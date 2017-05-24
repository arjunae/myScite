// Scintilla source code edit control
/** @file LexMake.cxx
 ** Lexer for make files.
 **/
// Copyright 1998-2001 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
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
    char *lineBuffer,
    Sci_PositionU lengthLine,
    Sci_PositionU startLine,
    Sci_PositionU endPos,
		WordList *keywordlists[],
    Accessor &styler) {
	
	Sci_PositionU i = 0;
	Sci_Position lastNonSpace = -1;
	unsigned int state = SCE_MAKE_DEFAULT;
	bool bSpecial = false;

	/*
	// todo fetch current word to search for below
	WordList &kwDirective = *keywordlists[0]; // Directives

	if (kwDirective.InList(words)) {
		styler.ColourTo(endPos, SCE_MAKE_VARIABLE);
		return;
	}	
	*/
	
	// check for a tab character in column 0 indicating a command
	bool bCommand = false;
	if ((lengthLine > 0) && (lineBuffer[0] == '\t'))
		bCommand = true;

	// Skip initial spaces
	while ((i < lengthLine) && isspacechar(lineBuffer[i])) {
		i++;
	}
	if (i < lengthLine) {
		if (lineBuffer[i] == '#') {	// Comment
			styler.ColourTo(endPos, SCE_MAKE_COMMENT);
			return;
		}
		if (lineBuffer[i] == '!') {	// Special directive
			styler.ColourTo(endPos, SCE_MAKE_PREPROCESSOR);
			return;
		}
	}
	
	int varCount = 0; // increments on $
	int inVarCount = 0; // increments on identifiers within $vars @...D/F
	unsigned int state_prev;
	while (i < lengthLine) {
		// same Style for Variables $(...) and $ based automatic Variables $@
		if (((i + 1) < lengthLine) && lineBuffer[i] == '$' && (strchr( "(@%<?^+*",(int)lineBuffer[i+1]) >0))  {
			styler.ColourTo(startLine + i - 1, state);
			state_prev = state;
			state = SCE_MAKE_VARIABLE;
			varCount++;
		} else if (state == SCE_MAKE_VARIABLE && lineBuffer[i]==')') {
			if (--varCount == 0) {
				styler.ColourTo(startLine + i, state);
				state = state_prev;
			}
		} else if (state == SCE_MAKE_VARIABLE && (strchr( "@%<?^+*",(int)lineBuffer[i]) >0) && lineBuffer[i-1]=='$') {
			if (--varCount == 0) {
				styler.ColourTo(startLine + i, state);
				state = state_prev;
			}
		}
		
		// Style for automatic Variables in standard variables (@%<^+)
		if (((i + 1) < lengthLine) && (strchr( "@%<?^+*",(int)lineBuffer[i]) >0) && (strchr( "DF",(int)lineBuffer[i+1]) >0))  {
			styler.ColourTo(startLine + i -1 , state);
			state_prev=state;
			state = SCE_MAKE_IN_VARIABLE;
			inVarCount++;
		} else if (state == SCE_MAKE_IN_VARIABLE && (strchr( "@%<^+",(int)lineBuffer[i-1]) >0) && (strchr( "DF",(int)lineBuffer[i]) >0)) {
			if (--inVarCount == 0) {
				styler.ColourTo(startLine + i, state);
				state = state_prev;
			}
		}
	
		// skip identifier and target styling if this is a command line
		if (!bSpecial && !bCommand) {
			if (lineBuffer[i] == ':') {
				if (((i + 1) < lengthLine) && (lineBuffer[i + 1] == '=')) {
					// it's a ':=', so style as an identifier
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
					styler.ColourTo(startLine + i - 1, SCE_MAKE_DEFAULT);
					styler.ColourTo(startLine + i + 1, SCE_MAKE_OPERATOR);
				} else {
					// We should check that no colouring was made since the beginning of the line,
					// to avoid colouring stuff like /OUT:file
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_TARGET);
					styler.ColourTo(startLine + i - 1, SCE_MAKE_DEFAULT);
					styler.ColourTo(startLine + i, SCE_MAKE_OPERATOR);
				}
				bSpecial = true;	// Only react to the first ':' of the line
				state = SCE_MAKE_DEFAULT;
			} else if (lineBuffer[i] == '=') {
				if (lastNonSpace >= 0)
					styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
				styler.ColourTo(startLine + i - 1, SCE_MAKE_DEFAULT);
				styler.ColourTo(startLine + i, SCE_MAKE_OPERATOR);
				bSpecial = true;	// Only react to the first '=' of the line
				state = SCE_MAKE_DEFAULT;
			}
		}
		if (!isspacechar(lineBuffer[i])) {
			lastNonSpace = i;
		}
		
		i++;
	}
	
	if (state == SCE_MAKE_IDENTIFIER) {
		styler.ColourTo(endPos, SCE_MAKE_IDEOL);	// Error, variable reference not ended
	} else {
		styler.ColourTo(endPos, SCE_MAKE_DEFAULT);
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

static const char *const emptyWordListDesc[] = {
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", 0, emptyWordListDesc);
