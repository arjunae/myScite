// Scintilla source code edit control
/**
 * @file LexMake.cxx
 * @author Neil Hodgson, Thorsten Kani(marcedo@HabMalneFrage.de)
 * @brief Lexer for make files
 * @brief 26.06.17 | Thorsten Kani | Add more Styles
 * - GNUMake Directives, internal $(sort subst..) function Keywords,
 * - $@%<?^+* Automatic Variables, "-" Flags and Keywords for externalCommands
 * - Warns on more unclosed Brackets or doublequoted Strings.
 * @brief todos
 * todo: store and style User defined Varnames. ( myvar=... )
 * todo: handle line continuation character. "\"
 * todo: handle VC Makefiles ( eg //D , strings and numbers in general.)
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
	return (strchr("&|-@\t\r\n \":, '({", (int)(styler.SafeGetCharAt(i))) >0);
}

static unsigned int ColouriseMakeLine(
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

	styler.Flush();

	// check for a tab character in column 0 indicating a command
	bool bCommand = false;
	if ((lengthLine > 0) && (slineBuffer[0] == '\t'))
		bCommand = true;

	// Skip initial spaces and tabs for current Line. Spot that Position to check for later.
	while ((i < lengthLine) && isspacechar(slineBuffer[i]))
		i++;

	unsigned int theStart=i; // One Byte ought (not) to be enough for everyone....?

	if (i < lengthLine) {
		if (slineBuffer[i] == '!') {	// Special directive
			state_prev=state;
			state=SCE_MAKE_PREPROCESSOR;
			styler.ColourTo(endPos, state);
			return (state);
		}
	}

	// color keywords within current line.
	WordList &kwGeneric = *keywordlists[0]; // Makefile->Directives
	WordList &kwFunctions = *keywordlists[1]; // Makefile->Functions (ifdef,define...)
	WordList &kwExtCmd = *keywordlists[2]; // Makefile->external Commands (mkdir,rm,attrib...)

	unsigned int strLen=0;
	unsigned int startMark=0;
	bool inString=false;
	int iWarnEOL=0;

	while (i < lengthLine) {

		char chNext=styler.SafeGetCharAt(startLine +i+1);

		// skip identifier and target styling if this is a command line
		if (!bSpecial && !bCommand && state==SCE_MAKE_DEFAULT) {
			if (slineBuffer[i] == ':') {
				if (i<lengthLine && (chNext == '=')) {
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

		// lets signal a warning on unclosed Strings or Brackets.
		if (strchr("({", (int)slineBuffer[i]) >0) {
			state_prev=state;
			state=SCE_MAKE_IDENTIFIER;
			if (i>0)
				styler.ColourTo(startLine + i-1, state_prev);
			styler.ColourTo(startLine + i, state);
			state=state_prev;
			iWarnEOL++;
		} else if (strchr(")}", (int)slineBuffer[i]) >0) {
			state_prev=state;
			state=SCE_MAKE_IDENTIFIER;
			styler.ColourTo(startLine + i, state);
			state=state_prev;
			iWarnEOL--;
		}	else if (inString && slineBuffer[i]=='\"') {
			iWarnEOL--;
			inString=false;
		} else if	(!inString && slineBuffer[i]=='\"') {
			inString=true;
			iWarnEOL++;
		}

		// ForwardSearch Searchstring.
		// Travels to the Future and retrieves Lottery draw results.
		std::string strSearch;

		/// cpplusplus.com: any return values from isgraph (and co) >0 should be considered true.
		if (isgraph(slineBuffer[i]) == 0) {
			startMark=0;
			strLen=0;
		}

		// got alphanumerics we mark the wordBoundary.
		if (isalnum(slineBuffer[i])>0 && strLen == 0) {
			strLen++;
			startMark=i; // absolute position of current words begin.
		} else if (strLen>0) {
			strLen++; // ... within a word dimension boundary.
		}

		// got the other End, copy the word:
		if (isalnum(chNext) == 0 && strLen > 0) {
			strSearch=slineBuffer.substr(startMark, strLen);
			strLen=0;
			startMark=0;
		}

		if (strSearch.size()>0) {

			Sci_PositionU wordLen=(Sci_PositionU)strSearch.size();

			// check if we get a match with Keywordlist externalCommands
			// Rule: Prepended by line start or " \t\r\n /\":,\=" Ends on eol,whitespace or ;
			if (kwExtCmd.InList(strSearch.c_str()) && inString==false && (strchr("\t\r\n ;", (int)chNext) >0)
					&& (i+1 -wordLen == theStart || AtStartChar(styler, startLine +i -wordLen))) {
				styler.ColourTo(startLine +i-wordLen, state);
				state_prev=state;
				state=SCE_MAKE_EXTCMD;
				styler.ColourTo(startLine +i, state);
			} else if (state == SCE_MAKE_EXTCMD) {
				state=SCE_MAKE_DEFAULT;
				styler.ColourTo(startLine + i, state);
			}

			// we now search for the word within the Directives Space.
			// Rule: Prepended by whitespace,precedet by line start or .'='.
			if (kwGeneric.InList(strSearch.c_str()) && inString==false && (strchr("\t\r\n ;", (int)chNext) >0)
					&& (i+1 -wordLen == theStart || styler.SafeGetCharAt(startLine +i -wordLen-1) == '=')) {
				state_prev=state;
				state=SCE_MAKE_DIRECTIVE;
				styler.ColourTo(startLine + i, state);
			} else if (state == SCE_MAKE_DIRECTIVE) {
				state=state_prev;
				styler.ColourTo(startLine +i, SCE_MAKE_DEFAULT);
			}

			// ....and within functions $(sort,subst...) / used to style internal Variables too.
			// Rule: have to be prefiixed by '('
			if (kwFunctions.InList(strSearch.c_str())
					&& styler.SafeGetCharAt(startLine +i -wordLen -1) == '$'
					&& styler.SafeGetCharAt(startLine +i -wordLen) == '(') {
				state_prev=state;
				state=SCE_MAKE_OPERATOR;
				styler.ColourTo(startLine + i, state);
			} else if (slineBuffer[i] == ')') {
				//state=SCE_MAKE_DEFAULT;
			}

			startMark=0;
			strLen=0;
			strSearch.clear();
		}

		// Style User Variables Rule: $(...)
		if (slineBuffer[i] == '$' && (strchr("{(", (int)chNext) >0)) {
			styler.ColourTo(startLine +i-1, SCE_MAKE_DEFAULT); // styles the $ too.
			state_prev=state;
			state = SCE_MAKE_USER_VARIABLE;
			// ... and $ based automatic Variables Rule: $@%<?^+*
		} else if (slineBuffer[i] == '$' && (strchr("@%<?^+*", (int)chNext)) >0) {
			styler.ColourTo(startLine +i-1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (SCE_MAKE_USER_VARIABLE && (strchr("})", (int)chNext) >0)) {
			styler.ColourTo(startLine +i, state);
			state = state_prev;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<?^+*", (int)slineBuffer[i])) >0) {
			styler.ColourTo(startLine +i, state);
			state = state_prev;
		}

		// Style for automatic Variables. FluxCompensators orders: @%<^+'D'||'F'
		if ((strchr("@%<?^+*", (int)slineBuffer[i]) >0) && (strchr("DF", (int)chNext) >0)) {
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<^+", (int)styler.SafeGetCharAt(startLine+i-1))>0 && (strchr("DF", (int)slineBuffer[i]) >0))) {
			styler.ColourTo(startLine +i, state);
			state = state_prev;
		}

		// Capture the Flags. Start match:  ( '-' ) or  (linestart + "-") or ("=-") Endmatch: (whitespace || EOL || "$./:\,'.")
		if ((i<lengthLine && inString==false && (isalnum(slineBuffer[i])==0 && chNext=='-'))
				|| (i == theStart && slineBuffer[i] == '-')) {
			styler.ColourTo(startLine + i, state_prev);
			state_prev=state;
			state = SCE_MAKE_FLAGS;
		} else if (state==SCE_MAKE_FLAGS && strchr("$\t\r\n /\\\":,\''.", (int)chNext) >0) {
			styler.ColourTo(startLine + i, state);
			styler.ColourTo(startLine + i, state_prev);

			state = SCE_MAKE_DEFAULT;
		}

		if (slineBuffer[i] == '#' && iWarnEOL<1) {	// support GNUMake inline Comments
			state_prev=state;
			state=SCE_MAKE_COMMENT;
			styler.ColourTo(endPos, state);
			return (state);
		}

		if (!isspacechar(slineBuffer[i]))
			lastNonSpace = i;

		i++;
	}

	if (iWarnEOL>0) {
		state=SCE_MAKE_IDEOL; // Error, String or bracket reference unclosed.
	} else if (iWarnEOL<1) {
		state=SCE_MAKE_DEFAULT;
	}

	styler.ColourTo(endPos, state);
	//styler.ChangeLexerState(startLine, endPos);

	return (state);
}

/**
// @brief returns a multilines startPosition or current Lines start
// if the Position does not belong to a Multiline Segment
**/
static int ckMultiLine(Accessor &styler, Sci_Position offset) {

	int status=0; // 1=cont_end 2=cont_middle/start
	Sci_Position currMLSegment=0;
	Sci_Position finalMLSegment=0;

	// check if current lines last visible char is a continuation
	Sci_Position pos=offset;
	while (styler[++pos]!='\n');
	// moves to last visible char
	while (isgraph(styler.SafeGetCharAt(--pos)==0));
	pos--;
	if (styler[pos]=='\\') {
		status=2;
	} else {
		status=1;
		currMLSegment=offset;
		finalMLSegment=offset;
	}

	//  check for continuation segments start
	pos = styler.LineStart(styler.GetLine(pos)-1);
	while (currMLSegment >0) {
		while (styler[++pos]!='\n');
		while (isgraph(styler.SafeGetCharAt(--pos)==0));
		pos--;
		if (styler[pos]!='\\') {
			if (status==1) {
				currMLSegment=finalMLSegment;
				break; // no MultiLine
			} else {
				break; // firstSegment reached.
			}
		} else { // continue search
			currMLSegment=styler.LineStart(styler.GetLine(pos));
			pos = styler.LineStart(styler.GetLine(pos)-1);
			status=2;
		}
	}

	return (currMLSegment);
}

static void ColouriseMakeDoc(Sci_PositionU startPos, Sci_Position length, int, WordList *keywords[], Accessor &styler) {
	char lineBuffer[1024]; // ok. i _really_ do like vectors from now on...

	// For efficiency reasons, scintilla calls the lexer with the cursors current position and a reasonable length.
	// Its up to the lexer to check if the cursor position is in Fact part of a previous Lines continuation.
	// took me much longer to get that obvious fact then to come up with a nearly oneLiner....

	// find that (Multi)lines start.
	Sci_Position o_startPos=ckMultiLine(styler, startPos);
	styler.StartSegment(o_startPos);
	styler.StartAt(o_startPos);
	length=length+(startPos-o_startPos);
	startPos=o_startPos;

	Sci_PositionU lineLength = 0;
	Sci_PositionU lineStart = startPos;
	Sci_Position ywo=0;

	for (Sci_PositionU at = startPos; at < startPos + length; at++) {
		lineBuffer[lineLength++] = styler[at];

		// End of line (or of max line buffer) met.
		if (AtEOL(styler, at) || (lineLength >= sizeof(lineBuffer) - 1)) {
			ywo=at;

			// check last visible char for beeing a continuation
			while (isgraph(styler[ywo--])==0 && lineLength>2);
			ywo++;
			if (styler.SafeGetCharAt(ywo) =='\\') {
				// ...get its lineEnd
				while (ywo <length) {
					// c fun: imagin a corner case without \n.
					//where linelength would exeec lineBuffers lenght and invalidate var start within memory...
					while (styler[ywo++] && styler[ywo]!='\n' && styler[ywo]!='\0')
						lineBuffer[lineLength++] = styler[ywo];

					// ... but check if this lines is another continuation
					Sci_Position pos;
					for (pos=ywo; isgraph(styler.SafeGetCharAt(pos))==0; pos--);
					if (styler[pos] !='\\') {	// Fin. Request Screen redraw.
						styler.ChangeLexerState(startPos, startPos+length);
						break;
					}
					ywo++;
				}
				at=ywo++;

			}
			lineBuffer[lineLength] = '\0';

			ColouriseMakeLine(lineBuffer, lineLength, lineStart, at, keywords, styler);
			lineStart = at + 1;
			lineLength = 0;
		}
	}
	if (lineLength>0)
		ColouriseMakeLine(lineBuffer, lineLength, lineStart, startPos+length -1, keywords, styler);
}

static const char *const makefileWordListDesc[] = {
	"generica",
	"functions",
	"kwExtCmd",
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", 0, makefileWordListDesc);