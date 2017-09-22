// Scintilla source code edit control
/**
 * @file LexMake.cxx
 * @author Neil Hodgson, Thorsten Kani(marcedo@HabMalneFrage.de)
 * @brief Lexer for make files
 * @brief 18.07.17 | Thorsten Kani | Add more Styles
 * - GNUMake Directives, internal function Keywords  $(sort subst..) ,
 * - Automatic Variables $@%<?^+* , Flags "-" and Keywords for externalCommands
 * - Warns on more unclosed Brackets or doublequoted Strings.
 * - Handles multiLine Continuations, inlineComments and styles Strings.
 * @brief todos
 * todo: store and style User defined Varnames. ( myvar=... )
 * todo: handle VC Makefiles ( eg //D and numbers in general.)
 * @brief Copyright 1998-2001 by Neil Hodgson <neilh@scintilla.org>
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

static inline bool AtStartChar(Accessor &styler, Sci_PositionU i) {
	return (strchr("&|@\t\r\n -\":, '({", (int)(styler.SafeGetCharAt(i)))!=NULL);
}

static inline bool IsNewline(const int ch) {
	return (ch == '\n' || ch == '\r');
}

// win10 -german chars ö ½ ï¿½ .. translate to negative values ?
static inline int IsAlphaNum(int ch) {
	if ((IsASCII(ch) && isalpha(ch)) || ((ch >= '0') && (ch <= '9')))
		return (1);

	return (0);
}

static inline int IsGraphic(int ch) {
	if (ch>0) return (isgraph(ch));
	return (IsAlphaNum(ch));
}

static inline void ColourHere(Accessor &styler, Sci_PositionU pos, unsigned int style1, unsigned int style2) {
	styler.ColourTo(pos, style1);
	styler.ColourTo(pos, style2);
}

static unsigned int ColouriseMakeLine(
	std::string slineBuffer,
	Sci_PositionU lengthLine,
	Sci_PositionU startLine,
	Sci_PositionU endPos,
	WordList *keywordlists[],
	Accessor &styler) {

	Sci_PositionU i = 0; // primary line position counter
	Sci_Position lastNonSpace = -1;
	Sci_Position lastSpaceWord = 0;
	
	unsigned int state = SCE_MAKE_DEFAULT;
	unsigned int state_prev = SCE_MAKE_DEFAULT;

	bool bSpecial = false; // Only react to the first '=' or ':' of the line.
	unsigned int strLen=0; // Keyword candidate length.
	unsigned int startMark=0; // Keyword candidates startPos.
	bool inString=false; // set when a double quoted String begins.
	bool inSqString=false; // set when a single quoted String begins.
	
	int iWarnEOL=0;// unclosed string bracket refcount.

	/// keywords
	WordList &kwGeneric = *keywordlists[0]; // Makefile->Directives
	WordList &kwFunctions = *keywordlists[1]; // Makefile->Functions (ifdef,define...)
	WordList &kwExtCmd = *keywordlists[2]; // Makefile->external Commands (mkdir,rm,attrib...)
	
	// check for a tab character in column 0 indicating a command
	bool bCommand = false;
	if ((lengthLine > 0) && (styler.SafeGetCharAt(startLine) == '\t'))
		bCommand = true;

	// Skip initial spaces and tabs for current Line. Spot that Position to check for later.
	while ((i < lengthLine) && isspacechar(styler.SafeGetCharAt(startLine+i)))
		i++;

	unsigned int theStart=i; // One Byte ought (not) to be enough for everyone....?

	// Style special directive
	if (i < lengthLine) {
		if (styler.SafeGetCharAt(startLine+i) == '!') {
			state_prev=state;
			state=SCE_MAKE_PREPROCESSOR;
			styler.ColourTo(endPos, state);
			return(state);
		}
	}
	
	while (i < lengthLine) {
		unsigned int currentPos=startLine+i;
		char chCurr=styler.SafeGetCharAt(currentPos);
		char chNext=styler.SafeGetCharAt(currentPos+1);

		/// style GNUMake inline Comments
		if (chCurr == '#' && !inString && !inSqString) {
			state_prev=state;
			state=SCE_MAKE_COMMENT;
			if (i>0) styler.ColourTo(currentPos-1, state_prev);
			ColourHere(styler, endPos, state, SCE_MAKE_DEFAULT);
			return(state);
		}
		
		/// Style Target lines
		// skip identifier and target styling if this is a command line
		if (!bSpecial && !bCommand) {
		state_prev=state;
			if (chCurr == ':') {
				if (i<lengthLine && (chNext == '=')) {
					// it's a ':=', so style as an identifier
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
					styler.ColourTo(currentPos -1, SCE_MAKE_DEFAULT);
					styler.ColourTo(currentPos +1, SCE_MAKE_OPERATOR);
				} else if(isspace(chNext)) {
					// We should check that no colouring was made since the beginning of the line,
					// to avoid colouring stuff like /OUT:file
					if (lastSpaceWord >0 && lastSpaceWord < lastNonSpace-1)
						styler.ColourTo(startLine + lastSpaceWord, SCE_MAKE_DEFAULT);
					if (lastNonSpace >= 0)
						styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_TARGET);
					styler.ColourTo(currentPos -1, SCE_MAKE_DEFAULT);
					ColourHere(styler, currentPos, SCE_MAKE_OPERATOR, SCE_MAKE_DEFAULT);
				}
				//bSpecial = true;	// Only react to the first ':' of the line
				state = SCE_MAKE_DEFAULT;
			} else if (chCurr== '=') {
				if (lastSpaceWord >0 && lastSpaceWord < lastNonSpace-1)
					styler.ColourTo(startLine + lastSpaceWord, SCE_MAKE_DEFAULT);
				if (lastNonSpace >= 0)
					styler.ColourTo(startLine + lastNonSpace, SCE_MAKE_IDENTIFIER);
				styler.ColourTo(currentPos -1, SCE_MAKE_DEFAULT);
				ColourHere(styler, currentPos,SCE_MAKE_OPERATOR, SCE_MAKE_DEFAULT);
				//bSpecial = true;	// Only react to the first '=' of the line
				}
				state = state_prev;
		}
		
		/// lets signal a warning on unclosed Strings or Brackets.
		if (strchr("({", (int)chCurr)!=NULL) {
			if (i>0) styler.ColourTo(currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			iWarnEOL++;
		} else if (strchr(")}>", (int)chCurr)!=NULL) {
			if (i>0) styler.ColourTo(currentPos-1, state);
			ColourHere(styler, currentPos,SCE_MAKE_IDENTIFIER, state);
			iWarnEOL--;
		}

		/// Style double quoted Strings
		if (inString && chCurr=='\"') {
			if (i>0) styler.ColourTo(currentPos-1, state);
			state=SCE_MAKE_DEFAULT;
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			iWarnEOL--;
			inString=false;
		} else if	(!inString && chCurr=='\"') {
			state_prev = state;
			state=SCE_MAKE_STRING;
			if (i>0) styler.ColourTo(currentPos-1, state_prev);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			inString=true;
			iWarnEOL++;
		}

		/// Style single quoted Strings. Don't EOL check for now. 
		if (!inString && inSqString && chCurr=='\'') {
			if (i>0) styler.ColourTo(currentPos-1, state);
			state=SCE_MAKE_DEFAULT;
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			inSqString=false;
		} else if	(!inString && !inSqString && chCurr=='\'') {
			state_prev = state;
			state=SCE_MAKE_STRING;
			if (i>0) styler.ColourTo(currentPos-1, state_prev);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			inSqString=true;
		}
		
		/// hm. Colour some Delimiters...Just because its Fun :)
		if (strchr("[<'|\">?&]", (int)chCurr) !=NULL) {
			if (i>0) styler.ColourTo(currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
		}
	
		/// Style Keywords
		// ForwardSearch Searchstring.
		// Travels to the Future and retrieves Lottery draw results.
		std::string strSearch;

		/// cpplusplus.com: any return values from IsAlphaNum (and co) >0 should be considered true.
		if (IsGraphic(chCurr) == 0) {
			startMark=0;
			strLen=0;
		}

		// got alphanumerics we mark the wordBoundary.
		if (IsAlphaNum(chCurr)>=1 && strLen == 0) {
			strLen++;
			startMark=i; // absolute position of current words begin.
		} else if (strLen>0) {
			strLen++; // ... within a word dimension boundary.
		}

		// got the other End, copy the word:
		if (IsAlphaNum(chNext) == 0 && strLen > 0) {
			strSearch=slineBuffer.substr(startMark, strLen);
			strLen=0;
			startMark=0;
		}

		// Ok, now we have some materia within our char buffer.  Check whats in:
		if (strSearch.size()>0 && IsAlphaNum(chNext) == 0) {
			Sci_PositionU wordLen=(Sci_PositionU)strSearch.size();

			// check if we get a match with Keywordlist externalCommands
			// Rule: Prepended by line start or " \t\r\n /\":,\=" Ends on eol,whitespace or ;
			if (kwExtCmd.InList(strSearch.c_str()) 
					&& inString==false && (strchr("\t\r\n ;)", (int)chNext) !=NULL)
					&& (i+1 -wordLen == theStart || AtStartChar(styler, startLine +i -wordLen))) {
				if (i>0) styler.ColourTo(currentPos-wordLen, SCE_MAKE_DEFAULT);
				state_prev=state;
				state=SCE_MAKE_EXTCMD;
				styler.ColourTo(currentPos-wordLen, state_prev);
				ColourHere(styler, currentPos, state, SCE_MAKE_DEFAULT);
			} else if (state == SCE_MAKE_EXTCMD) {
				state=SCE_MAKE_DEFAULT;
				styler.ColourTo(currentPos, state);
			}

			// we now search for the word within the Directives Space.
			// Rule: Prepended by whitespace, preceedet by line start or .'='.
			if (kwGeneric.InList(strSearch.c_str()) 
					&& inString==false && (strchr("\t\r\n ;)", (int)chNext) !=NULL)
					&& (i+1 -wordLen == theStart || styler.SafeGetCharAt(startLine +i -wordLen-1) == '=')) {
				state_prev=state;
				state=SCE_MAKE_DIRECTIVE;
				ColourHere(styler, currentPos, state, SCE_MAKE_DEFAULT);
			} else if (state == SCE_MAKE_DIRECTIVE) {
				state=SCE_MAKE_DEFAULT;
				styler.ColourTo(currentPos, state);
			}

			// ....and within functions $(sort,subst...) / used to style internal Variables too.
			// Rule: have to be prefixed by '(' and preceedet by whitespace or ;)
			if (kwFunctions.InList(strSearch.c_str())
					&& styler.SafeGetCharAt(startLine +i -wordLen -1) == '$'
					&& styler.SafeGetCharAt(startLine +i -wordLen) == '(') {
				state_prev=state;
				state=SCE_MAKE_OPERATOR;
				ColourHere(styler, currentPos, state, SCE_MAKE_DEFAULT);
			} else if (state ==SCE_MAKE_OPERATOR) {
				state=SCE_MAKE_DEFAULT;
				styler.ColourTo(currentPos, state);
			}
			startMark=0;
			strLen=0;
			strSearch.clear();
		}

		/// Style User Variables Rule: $(...)
		if (chCurr == '$' && (strchr("{(", (int)chNext)!=NULL)) {
			if (i>0) styler.ColourTo(currentPos-1, state);
			state_prev=state;
			state = SCE_MAKE_USER_VARIABLE;
		} else if (state == SCE_MAKE_USER_VARIABLE && (strchr("})", (int)chNext)!=NULL)) {
			ColourHere(styler, currentPos, state, state_prev);
			state = state_prev;
		}

		/// ... and $ based automatic Variables Rule: $@%<?^+*
		if (chCurr == '$' && (strchr("@%<?^+*", (int)chNext))!=NULL) {
			if (i>0) styler.ColourTo(currentPos-1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<?^+*", (int)chCurr)!=NULL)) {			
			ColourHere(styler, currentPos, state, state_prev);
			state = state_prev;
		}

		/// Style for automatic Variables. FluxCompensators orders: @%<^+'D'||'F'
		if ((strchr("@%<?^+*", (int)chCurr) >0) && (strchr("DF", (int)chNext)!=NULL)) {
			if (i>0) styler.ColourTo(currentPos-1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE 
				&& (strchr("@%<^+", (int)styler.SafeGetCharAt(currentPos-1))!=NULL 
				&& (strchr("DF", (int)chCurr) !=NULL))) {
			ColourHere(styler, currentPos, state, state_prev);
			state = SCE_MAKE_DEFAULT;
		}

		/// Capture the Flags. Start match:  ( '-' ) or  (linestart + "-") or ("=-") Endmatch: (whitespace || EOL || "$./:\,'")
		if ((i<lengthLine && inString==false && (IsAlphaNum(chCurr)==0 && chNext=='-'))
				|| (i == theStart && chCurr == '-')) {
			state_prev=SCE_MAKE_DEFAULT;
			state = SCE_MAKE_FLAGS;
			bool j= (i>0 && (chCurr=='-') && chNext=='-') ? 1:0; // style both '-'
			styler.ColourTo(currentPos-j, state_prev);
		} else if (state==SCE_MAKE_FLAGS && strchr("$\t\r\n /\\\",\''", (int)chNext) !=NULL) {
			ColourHere(styler, currentPos, state, state_prev);
			state = SCE_MAKE_DEFAULT;
		}

		if (!isspacechar(chCurr)) {
			lastNonSpace = i;
		}
		
		if ((i<lengthLine && IsGraphic(chNext)!=NULL 
		&& strchr("\t =", (int)chCurr)!=NULL ) 
		|| strchr("();?&", (int)chNext)!=NULL ) {
			lastSpaceWord=i;
		}
		
		i++;
	}

	if (iWarnEOL>0) {
		state=SCE_MAKE_IDEOL;
	} else if (iWarnEOL<1) {
		state=SCE_MAKE_DEFAULT;
	}

	ColourHere(styler, endPos, state, SCE_MAKE_DEFAULT);
	return (state);
}

/**
// @brief returns a multilines startPosition or current lines start
// if the Position does not belong to a Multiline Segment.
**/
static int GetLineStart(Accessor &styler, Sci_Position offset) {

	int status=0; // 1=cont_end 2=cont_middle/start
	Sci_Position currMLSegment=0;
	Sci_Position prevMLSegment=0;
	Sci_Position finalMLSegment=0;

	// check if current lines last visible char is a continuation
	Sci_Position pos=offset;
	while (styler[pos++]!='\n');
	// moves to last visible char
	while (IsGraphic(styler.SafeGetCharAt(--pos)==0)) ;
	pos--;
	if (styler[pos]=='\\') {
		status=2;
	} else {
		status=1;
		finalMLSegment=offset;
	}

	//  check for continuation segments start
	pos = styler.LineStart(styler.GetLine(pos)-1);
	while (pos != currMLSegment) {
		currMLSegment=pos;
		while (styler[++pos]!='\n');
		if ((status==2 && styler[pos+1]=='\r') || styler[pos+1]=='\n')
			break; // empty line reached
		while (iscntrl(styler.SafeGetCharAt(--pos)));
		pos--;
		if (styler[pos]!='\\' && styler[pos+1]!='\\') {
			if (status==1) {
				currMLSegment=finalMLSegment;
				break; // no MultiLine
			} else {
				currMLSegment=prevMLSegment;
				break; // firstSegment reached.
			}
		} else { // continue search
			prevMLSegment=styler.LineStart(styler.GetLine(pos));
			pos = styler.LineStart(styler.GetLine(pos)-1);
			status=2;
		}
	}
	return (currMLSegment);
}

/**
// @brief returns a multilines length or current lines length
// if the Position does not belong to a Multiline Segment.
**/
static int GetLineLen(Accessor &styler, Sci_Position offset) {
	Sci_PositionU length=0;
	Sci_Position ywo=offset;

	// check last visible char for beeing a continuation
	while (ywo>0 && IsNewline(styler[ywo--])) {
		if (styler[ywo]=='\n') return (offset-ywo); // empty Line
	}

	if (styler[ywo+1]=='\\') {
		// ..begin at current lines startpos
		while (ywo>=0 && !IsNewline(styler[--ywo]));

		// ...get continued lines length
		while (true) {

			//..get Segments lineEnd
			while (styler[ywo++]) {
				length++;
				if (styler[ywo]=='\n' || styler[ywo]=='\0') break;
			}

			// ...Final continuation==Fini
			// cope with unix and windows style line ends.
			if (styler[ywo-1] !='\\' && styler[ywo-2] !='\\' && styler[ywo]=='\n') {
				return (length); // Continuation end reached.
				break;
			} else if (styler[ywo]=='\0') {
				return (length-1);	// handle continuated lines without an EOL mark.
				break;
			}
		}
	} else {
		// Handle non-contigous lines
		if (styler[ywo]!='\n')
			while (ywo>=0 && styler[--ywo]!='\n');

		return (offset-ywo);
	}
	
	return (offset-ywo);
}

static void ColouriseMakeDoc(Sci_PositionU startPos, Sci_Position length, int, WordList *keywords[], Accessor &styler) {

	const int MAX=4096;
	char lineBuffer[MAX]; //Note: allocate him on the heap. 
	memset(lineBuffer, 0, sizeof(*lineBuffer));
	styler.Flush();

	// For efficiency reasons, scintilla calls the lexer with the cursors current position and a reasonable length.
	// If that Position is within a continued Multiline, we notify the start position of that Line to Scintilla here:
	// finds a (Multi)lines start.
	Sci_PositionU o_startPos=GetLineStart(styler, startPos);
	styler.StartSegment(o_startPos);
	styler.StartAt(o_startPos);
	length=length+(startPos-o_startPos);
	startPos=o_startPos;
	
	Sci_PositionU linePos = 0;
	Sci_PositionU lineStart = startPos;
	for (Sci_PositionU at = startPos; at < startPos + length; at++) {

		lineBuffer[linePos++] = styler[at];
		// End of line (or of max line buffer) met.
		if (AtEOL(styler, at) || (linePos>= sizeof(lineBuffer) - 1)) {
			Sci_PositionU lineLength=GetLineLen(styler, at);
			lineLength=(lineLength<MAX) ? lineLength:MAX;

			// Copy the remaining chars to the lineBuffer.
			if (lineLength != linePos)
				for (Sci_PositionU posi=linePos-1; posi<=lineLength ; posi++)
					lineBuffer[posi]=styler[at++];

			at=lineStart+lineLength-1;
			
			ColouriseMakeLine(lineBuffer, lineLength, lineStart, at, keywords, styler);
			memset(lineBuffer, 0, lineLength);
			lineStart = at+1;
			linePos=0;
			styler.ChangeLexerState(startPos, startPos+lineLength); // Fini -> Request Screen redraw.
		}
	}
	if (linePos>0) // handle normal lines without an EOL mark.
		ColouriseMakeLine(lineBuffer, linePos, lineStart, startPos+length -1, keywords, styler);
}

static const char *const makefileWordListDesc[] = {
	"generica",
	"functions",
	"kwExtCmd",
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", 0, makefileWordListDesc);