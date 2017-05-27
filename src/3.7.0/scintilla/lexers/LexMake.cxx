// Scintilla source code edit control
/** @file LexMake.cxx
 ** Lexer for make files.
 **/
// Copyright 1998-2001 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>

#include "ILexer.h"
#include "Scintilla.h"
#include "SciLexer.h"

#include "WordList.h"
#include "LexAccessor.h"
#include "Accessor.h"
#include "StyleContext.h"
#include "CharacterSet.h"
#include "LexerModule.h"

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

static inline bool AtEOL(Accessor &styler, Sci_PositionU i) {
	return (styler[i] == '\n') ||
	       ((styler[i] == '\r') && (styler.SafeGetCharAt(i + 1) != '\n'));
}

static void ColouriseMakeLine(
	std::string slineBuffer,
	Sci_PositionU lengthLine,
	Sci_PositionU startLine,
	Sci_PositionU endPos,
	WordList *keywordlists[],
	Accessor &styler) {
	
	Sci_PositionU i = 0;
	Sci_Position lastNonSpace = -1;
	unsigned int state = SCE_MAKE_DEFAULT;
	unsigned int state_prev = SCE_MAKE_DEFAULT;
	bool bSpecial = false;

	// check for a tab character in column 0 indicating a command
	bool bCommand = false;
	if ((lengthLine > 0) && (slineBuffer[0] == '\t'))
		bCommand = true;

	// Skip initial spaces
	while ((i < lengthLine) && isspacechar(slineBuffer[i])) {
		i++;
	}

	// Create Word Buffer for current Line (from lexBatch)
	std::string wordBuffer;	// Word Buffer

	if (i < lengthLine) {
		if (slineBuffer[i] == '#') {	// Comment
			styler.ColourTo(endPos, SCE_MAKE_COMMENT);
			return;
		}
		if (slineBuffer[i] == '!') {	// Special directive
			styler.ColourTo(endPos, SCE_MAKE_PREPROCESSOR);
			return;
		}
	}

	int varCount = 0; // increments on $
	int inVarCount = 0; // increments on identifiers within $vars @...D/F

	while (i < lengthLine) {
		wordBuffer.append(slineBuffer.substr(i,1));

		// color keywords within current line
		WordList &kwGeneric = *keywordlists[0]; // Makefile->Directives
		WordList &kwFunctions = *keywordlists[1]; // Makefile->Functions (ifdef,define...)

		// search for longest keyword match backwards from current position. Case dependent.
		std::string wordPart;
		unsigned int match_kw0=0;
		unsigned int match_kw1=0;
		for (unsigned int matchpos=0; matchpos<=wordBuffer.size(); matchpos++) {
			wordPart.insert(0, wordBuffer.substr(wordBuffer.size()-matchpos, 1));
			if (kwGeneric.InList(wordPart.c_str()))
				match_kw0=matchpos;
			if (kwFunctions.InList(wordPart.c_str()))
				match_kw1=matchpos;
		}

		// style for Directives. Rule: Prepended by whitespace, = or line start.
		if (match_kw0 >0 
			&& (isspacechar(slineBuffer[i -match_kw0]) 
			|| slineBuffer[i -match_kw0] == 0 
			|| slineBuffer[i -match_kw0] == '=')) {
			styler.ColourTo(startLine +i -match_kw0, state);
			state_prev = state;
			state=SCE_MAKE_DIRECTIVE;
		} else if (match_kw0 == 0 && state == SCE_MAKE_DIRECTIVE) {
			styler.ColourTo(startLine +i -1, state);
			state=state_prev;
		}

		// style functions $(sort,subst...) and predefined Variables Rule: have to be prepended by '('.
		if (match_kw1 >0 && slineBuffer[i -match_kw1] == '(') {
			styler.ColourTo(startLine +i -match_kw1, state);
			state_prev = state;
			state=SCE_MAKE_OPERATOR;
		} else if (match_kw1 == 0 && state == SCE_MAKE_OPERATOR) {
			styler.ColourTo(startLine +i-1, state);
			state=state_prev;
		}

		// Style User Variables Rule: $(...)
		if (((i + 1) < lengthLine) && slineBuffer[i] == '$' && slineBuffer[i+1] == '(')  {
			styler.ColourTo(startLine +i -1, state);
			state = SCE_MAKE_USER_VARIABLE;
			varCount++;
			// ... and $ based automatic Variables Rule: $@
		} else if (((i + 1) < lengthLine) && slineBuffer[i] == '$' && (strchr("@%<?^+*", (int)slineBuffer[i+1]) >0)) {
			styler.ColourTo(startLine +i -1, state);
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if ((state == SCE_MAKE_USER_VARIABLE || state == SCE_MAKE_AUTOM_VARIABLE) && slineBuffer[i]==')') {
			if (--varCount == 0) {
				styler.ColourTo(startLine +i, state);
				state = state_prev;
			}
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<?^+*", (int)slineBuffer[i]) >0) && slineBuffer[i-1]=='$') {
			styler.ColourTo(startLine +i, state);
			state = SCE_MAKE_DEFAULT;
		}

		// Style for automatic Variables Rule: @%<^+'D'||'F'
		if (((i + 1) < lengthLine) && (strchr("@%<?^+*", (int)slineBuffer[i]) >0) && (strchr("DF", (int)slineBuffer[i+1]) >0))  {
			styler.ColourTo(startLine +i -1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
			inVarCount++;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<^+", (int)slineBuffer[i-1]) >0) && (strchr("DF", (int)slineBuffer[i]) >0)) {
			if (--inVarCount == 0) {
				styler.ColourTo(startLine +i, state);
				state = state_prev;
			}
		}

		// skip identifier and target styling if this is a command line
		if (!bSpecial && !bCommand) {
			if (slineBuffer[i] == ':') {
				if (((i + 1) < lengthLine) && (slineBuffer[i +1] == '=')) {
					// it's a ':=', so style as an identifier
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
					styler.ColourTo(startLine + i -1, SCE_MAKE_DEFAULT);
					styler.ColourTo(startLine + i +1, SCE_MAKE_OPERATOR);
				} else {
					// We should check that no colouring was made since the beginning of the line,
					// to avoid colouring stuff like /OUT:file
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_TARGET);
					styler.ColourTo(startLine + i -1, state_prev);
					styler.ColourTo(startLine + i, SCE_MAKE_OPERATOR);
				}
				bSpecial = true;	// Only react to the first ':' of the line
				state = state_prev;
			} else if (slineBuffer[i] == '=') {
				if (lastNonSpace >= 0)
					styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
				styler.ColourTo(startLine + i -1, state_prev);
				styler.ColourTo(startLine + i, SCE_MAKE_OPERATOR);
				bSpecial = true;	// Only react to the first '=' of the line
				state = state_prev;
			} else if (slineBuffer[i] == '{') {
				styler.ColourTo(startLine + i -1, state_prev);
				styler.ColourTo(startLine + i, SCE_MAKE_TARGET);
				state = state_prev;
			} else if (slineBuffer[i] == '}') {
				styler.ColourTo(startLine + i -1, state_prev);
				styler.ColourTo(startLine + i, SCE_MAKE_TARGET);
				state = state_prev;
			}

		}
		if (!isspacechar(slineBuffer[i])) {
			lastNonSpace = i;
		}
		
		if (state != SCE_MAKE_DEFAULT) {
			wordBuffer.clear();
			wordPart.clear();
		}
		
		i++;
	}

	if (state == SCE_MAKE_IDENTIFIER) {
		styler.ColourTo(endPos, SCE_MAKE_IDEOL);	// Error, variable reference not ended
	} else {
		styler.ColourTo(endPos, state_prev);
	}
}

static void ColouriseMakeDoc(Sci_PositionU startPos, Sci_Position length, int, WordList *keywords[], Accessor &styler) {
	char lineBuffer[1024];
	styler.StartAt(startPos);
	styler.StartSegment(startPos);
	Sci_PositionU linePos = 0;
	Sci_PositionU startLine = startPos;
	for (Sci_PositionU i = startPos; i < startPos + length; i++) {
		lineBuffer[linePos++] = styler[i];
		if (AtEOL(styler, i) || (linePos >= sizeof(lineBuffer) - 1)) {
			// End of line (or of line buffer) met, colourise it
			lineBuffer[linePos] = '\0';
			ColouriseMakeLine(lineBuffer, linePos, startLine, i, keywords, styler);
			linePos = 0;
			startLine = i + 1;
		}
	}
	if (linePos > 0) {	// Last line does not have ending characters
		ColouriseMakeLine(lineBuffer, linePos, startLine, startPos + length - 1, keywords, styler);
	}
}

static const char *const makefileWordListDesc[] = {
	"generic",
	"functions",
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", 0, makefileWordListDesc);
