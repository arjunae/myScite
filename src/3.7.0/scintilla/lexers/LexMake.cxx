// Scintilla source code edit control
/**
 * @file LexMake.cxx
 * @brief Lexer for make files
 * @author Neil Hodgson, Thorsten Kani(marcedo@HabMalneFrage.de)
 *
 * Copyright 1998-2001 by Neil Hodgson <neilh@scintilla.org>
 * The License.txt file describes the conditions under which this software may
 * be distributed.
 *
 */

#include <stdlib.h>
#include <string>
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

// todo: store and style User defined Varnames. ( myvar=... )
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
 
	// color keywords within current line
	WordList &kwGeneric = *keywordlists[0]; // Makefile->Directives
	WordList &kwFunctions = *keywordlists[1]; // Makefile->Functions (ifdef,define...)
	
	int strLen=0;
	int startMark=0;
	unsigned char theStart=i; // One Byte ought to be enough for everyone....?
	while (i < lengthLine) {

	// ForwardSearch Searchstring.
	// Travels to the Future and retrieves Lottery draw results. 
	std::string strSearch;
	
	/// cpplusplus.com: any return values from isgraph (and co) >0 should be considered true. 
	if (isgraph(slineBuffer[i]) == 0) { 
				startMark=0;
				strLen=0;	
			}

		// got alphanumerics, we mark the wordBoundary: 
		if (isalnum(slineBuffer[i])>0 
		 && strLen == 0) { 
			strLen++;
			startMark=i;
		} else if (strLen>0) {
			strLen++; // ... within a word dimension boundary.
		}

		// got the other End, copy the word:
		if (isalnum(slineBuffer[i+1]) == 0 && strLen>0) {
			strSearch=slineBuffer.substr(startMark,strLen);
			strLen=0;
			startMark=0;
		}
	
		if (strSearch.size()>0) {
		
		// we now search for the word within the Directives Space.
		// Rule: Prepended by whitespace, line start or .'='. 
		if (kwGeneric.InList(strSearch.c_str())
		 && (isspace(slineBuffer[i -strSearch.size()]) >0
			|| i+1 -strSearch.size() == theStart
			|| slineBuffer[i -strSearch.size()] == '=')) {		
			styler.ColourTo(startLine + i-strSearch.size(), state);
			state_prev=state;
			state=SCE_MAKE_DIRECTIVE;
			styler.ColourTo(startLine + i, state);
			state=state_prev;
		} else if (state == SCE_MAKE_DIRECTIVE) {
			state=state_prev;
			styler.ColourTo(endPos, state);
		}
		
		// ....and within functions $(sort,subst...) / used to style internal Variables too.
		// Rule: have to be prepended by '('.
		if (kwFunctions.InList(strSearch.c_str()) 
		 && slineBuffer[i -strSearch.size()] == '(') {
			styler.ColourTo(startLine + i-strSearch.size(), state);
			state_prev=state;
			state=SCE_MAKE_OPERATOR;
			styler.ColourTo(startLine + i, state);
			state=state_prev;
		} else if (state == SCE_MAKE_OPERATOR) {
			state=state_prev;
			styler.ColourTo(endPos, state);
		}
		startMark=0;
		strLen=0;
		strSearch.clear();
	}
				
		// Capture the Flags. Start match: (whitespace ''-' ) Endmatch:  whitespace, "." or '='
		if (((i + 1) < lengthLine) && slineBuffer[i+1]=='-' && (isspace(slineBuffer[i])>0 || slineBuffer[i]=='-')) {
			styler.ColourTo(startLine +i, state);
			state_prev=SCE_MAKE_DEFAULT;
			state = SCE_MAKE_FLAGS;
			}  else if (state == SCE_MAKE_FLAGS && (isspace(slineBuffer[i+1])>0 || (slineBuffer[i+1]=='=' || slineBuffer[i+1]=='.'))) {
			styler.ColourTo(startLine +i, state);
				state = state_prev;			
			}

		// Style User Variables Rule: $(...)
		if (((i + 1) < lengthLine) && slineBuffer[i] == '$' && slineBuffer[i+1] == '(') {
			styler.ColourTo(startLine +i -1, state);
			state = SCE_MAKE_USER_VARIABLE;
			// ... and $ based automatic Variables Rule: $@
		} else if (((i + 1) < lengthLine) && slineBuffer[i] == '$' && (strchr("@%<?^+*", (int)slineBuffer[i+1]) >0)) {
			styler.ColourTo(startLine +i -1, state);
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if ((state == SCE_MAKE_USER_VARIABLE || state == SCE_MAKE_AUTOM_VARIABLE) && slineBuffer[i] == ')') {
				styler.ColourTo(startLine +i, state);
				state = state_prev;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<?^+*", (int)slineBuffer[i]) >0) && slineBuffer[i-1] == '$') {
			styler.ColourTo(startLine +i, state);
			state = SCE_MAKE_DEFAULT;
		}

		// Style for automatic Variables. FluxCompensators orders: @%<^+'D'||'F'
		if (((i + 1) < lengthLine) && (strchr("@%<?^+*", (int)slineBuffer[i]) >0) && (strchr("DF", (int)slineBuffer[i+1]) >0)) {
			styler.ColourTo(startLine +i -1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<^+", (int)slineBuffer[i-1]) >0) && (strchr("DF", (int)slineBuffer[i]) >0)) {
				styler.ColourTo(startLine +i, state);
				state = state_prev;
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
	"generica",
	"functions",
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", 0, makefileWordListDesc);
