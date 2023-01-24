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
// todo: handle line continuation character. "\"
// todo: handle VC Makefiles ( eg //D and strings in general)
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
	int iWarnEOL=0; //  unclosed string refcount.

	while (i < lengthLine ) {

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
			&& (i+1 -(Sci_PositionU)strSearch.size() == theStart
			|| styler.SafeGetCharAt(startLine +i -(Sci_PositionU)strSearch.size()) == '=')) {
			state_prev=state;
			state=SCE_MAKE_DIRECTIVE;
			styler.ColourTo(startLine + i, state);
		} else if (!AtEOL(styler,i) && state == SCE_MAKE_DIRECTIVE && (isspacechar(slineBuffer[i+1]) >0)) {
			state=state_prev;
			styler.ColourTo(startLine +i, state);
		}
		
		// ....and within functions $(sort,subst...) / used to style internal Variables too.
		// Rule: have to be prefiixed by '(' 
		if (kwFunctions.InList(strSearch.c_str()) 
		 && styler.SafeGetCharAt(startLine +i -(Sci_PositionU)strSearch.size()) == '(') {
			state_prev=state;
			state=SCE_MAKE_OPERATOR;
			styler.ColourTo(startLine + i+1, state);
			state=state_prev;
		} else if (slineBuffer[i] == ')') {
			styler.ColourTo(startLine +i, state);
		}
		startMark=0;
		strLen=0;
		strSearch.clear();
	}
		
		// Style User Variables Rule: $(...)
		if (!AtEOL(styler,i) && slineBuffer[i] == '$' && slineBuffer[i+1] == '(') {
			styler.ColourTo(startLine +i -1, state);
			state_prev=state;
			state = SCE_MAKE_USER_VARIABLE;
			// ... and $ based automatic Variables Rule: $@
		} else if ((!AtEOL(styler,i)) && slineBuffer[i] == '$' && (strchr("@%<?^+*", (int)slineBuffer[i+1]) >0)) {
			styler.ColourTo(startLine +i -1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;			
		} else if (SCE_MAKE_USER_VARIABLE && slineBuffer[i] == ')') {
			styler.ColourTo(startLine +i, state);
			state = SCE_MAKE_DEFAULT;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<?^+*", (int)slineBuffer[i]) >0) && styler.SafeGetCharAt(startLine+i-1) == '$') {
			styler.ColourTo(startLine +i, state);
			state = state_prev;
		}

		// Style for automatic Variables. FluxCompensators orders: @%<^+'D'||'F'
		if (!AtEOL(styler,i) && (strchr("@%<?^+*", (int)slineBuffer[i]) >0) && (strchr("DF", (int)slineBuffer[i+1]) >0)) {
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
				if (!AtEOL(styler,i) && (slineBuffer[i +1] == '=')) {
					// it's a ':=', so style as an identifier
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
					styler.ColourTo(startLine + i -1, state_prev);
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
		}
	}
		// Capture the Flags. Start match:  ("=-") or ('-' | nonwhitespace + '-' ) Endmatch: (whitespace | EOL | "./:\,")
		if (((!AtEOL(styler,i) && isspace(slineBuffer[i])>0) && slineBuffer[i+1]=='-'  ) 
		|| (((!AtEOL(styler,i) && slineBuffer[i]=='-') || (slineBuffer[i]=='=' && slineBuffer[i+1]=='-')))) {
			styler.ColourTo(startLine +i, state);
			state_prev=SCE_MAKE_DEFAULT;
			state = SCE_MAKE_FLAGS;
			}  else if ((i<lengthLine && state == SCE_MAKE_FLAGS)
			&& ((strchr("\t\r\n /\\\":,", (int)slineBuffer[i+1]) >0) 
			|| (slineBuffer[i]=='.' && (slineBuffer[i+1]=='\\' || slineBuffer[i+1]=='/'))) // directories
			) {
			styler.ColourTo(startLine +i, state);
				state = state_prev;			
			}
		
			if (strchr("({[", (int)slineBuffer[i]) >0) {
				iWarnEOL++;
			} else if (strchr(")]}", (int)slineBuffer[i]) >0) {
				iWarnEOL--;
			}
		
		if ( !isspacechar(slineBuffer[i]) )
			lastNonSpace = i;

		i++;
	}
			

	if (iWarnEOL > 0) { 	
		state_prev=state;
		state=SCE_MAKE_IDEOL; // Error, variable reference not ended
	} else if (state==SCE_MAKE_IDEOL && iWarnEOL == 0){
		state=state_prev;
	} else {
		state=SCE_MAKE_DEFAULT;
	}
	styler.ColourTo(endPos, state);
		
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
