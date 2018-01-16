// Scintilla source code edit control
/**
 * @file LexMake.cxx
 * @author Neil Hodgson
 * @author Thorsten Kani(marcedo@HabMalneFrage.de)
 * @brief Lexer for make files
 * - Styles GNUMake Directives, internal function Keywords  $(sort subst..) ,
 * - Automatic Variables $[@%<?^+*] , Flags "-" and Keywords for externalCommands
 * - Warns on more unclosed Brackets or doublequoted Strings.
 * - Handles multiLine Continuations, inlineComments styles Strings and Numbers.
 * @brief 20.11.17 | Thorsten Kani | fixEOL && cleanUp | Folding from cMake.
 * @brief todos
 * todo: handle VC Makefiles ( eg //D )
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

// Some Files simply dont use LF/CRLF. 
// So use ~100kb as a maximum before simply style the rest in Defaults style.
#ifndef LEXMAKE_MAX_LINELEN
#define LEXMAKE_MAX_LINELEN  100000
#endif
#ifdef LEX_MAX_LINELEN
#define LEXMAKE_MAX_LINELEN  LEX_MAX_LINELEN
#endif

// Holds LEXMAKE_MAX_LINELEN or property "max.style.linelength" if it has been defined.
Sci_PositionU maxStyleLineLength;

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

static inline bool AtEOL(Accessor &styler, Sci_PositionU i) {
	return (styler[i] == '\n') ||
	       ((styler[i] == '\r') && (styler.SafeGetCharAt(i + 1) != '\n'));
}

static inline bool AtStartChar(Accessor &styler, Sci_PositionU i) {
	return (strchr("&|@\t\r\n -\":;, '({=", (int)(styler.SafeGetCharAt(i)))!=NULL);
}

static inline bool IsNewline(const int ch) {
	return (ch == '\n' || ch == '\r');
}

// replacement functions because german umlauts ö Ü .. translate to negative values.
static inline int IsNum(int ch) {
	if ((ch >= '0') && (ch <= '9'))
		return (1);

	return (0);
}

static inline int IsAlpha(int ch) {
	if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z'))
		return (1);

	return (0);
}

static inline int IsAlphaNum(int ch) {
	if (IsAlpha(ch) || IsNum(ch))
		return (1);

	return (0);
}

static inline int IsGraphic(int ch) {
	if (ch>0) return (isgraph(ch));
	return (IsAlphaNum(ch));
}

Sci_PositionU stylerPos; // Keep a Reference to the last styled Position.

static inline unsigned int ColourHere(Accessor &styler, Sci_PositionU pos, unsigned int style1) {
	if (pos<stylerPos) return stylerPos;
	styler.ColourTo(pos, style1);
	stylerPos=pos;
	return (pos);
}

static inline unsigned int ColourHere(Accessor &styler, Sci_PositionU pos, unsigned int style1, unsigned int style2) {
	if (pos<stylerPos) return stylerPos;
	styler.ColourTo(pos, style1);
	styler.ColourTo(pos, style2);
	stylerPos=pos;
	return (pos);
}

static unsigned int ColouriseMakeLine(
	std::string slineBuffer,
	Sci_PositionU lengthLine,
	Sci_PositionU startLine,
	Sci_PositionU endPos,
	WordList *keywordlists[],
	Accessor &styler,
	int startStyle) {

	Sci_PositionU i = 0; // primary line position counter
	Sci_PositionU styleBreak = 0;

	Sci_PositionU strLen = 0;				// Keyword candidate length.
	Sci_PositionU startMark = 0;	// Keyword candidates startPos. >0 while searching for a Keyword

	unsigned int SCE_MAKE_FUNCTION = SCE_MAKE_OPERATOR;
	unsigned int state = SCE_MAKE_DEFAULT;
	unsigned int state_prev = startStyle;

	union  {
		bool inString;			// set when a double quoted String begins.
		bool inSqString;	// set when a single quoted String begins	
		bool bCommand;			// set when a line begins with a tab (command)
		int iWarnEOL;				// unclosed string bracket refcount.
	} line;

	line.iWarnEOL=0;
	
	/// keywords
	WordList &kwGeneric = *keywordlists[0]; // Makefile->Directives
	WordList &kwFunctions = *keywordlists[1]; // Makefile->Functions (ifdef,define...)
	WordList &kwExtCmd = *keywordlists[2]; // Makefile->external Commands (mkdir,rm,attrib...)
	
	// check for a tab character in column 0 indicating a command
	if ((lengthLine > 0) && (styler.SafeGetCharAt(startLine) == '\t'))
		line.bCommand = true;

	// Skip initial spaces and tabs for current Line. Spot that Position to check for later.
	while ((i < lengthLine) && isspacechar(styler.SafeGetCharAt(startLine+i)))
		i++;

	unsigned int theStart=startLine+i; // One Byte ought (not) to be enough for everyone....?
	stylerPos=theStart; // Keep a Reference to the last styled Position.

	while ( i < lengthLine ) {
		Sci_PositionU currentPos=startLine+i;

		char chPrev=styler.SafeGetCharAt(currentPos-1);
		char chCurr=styler.SafeGetCharAt(currentPos);
		char chNext=styler.SafeGetCharAt(currentPos+1);
		
		/// Handle (very) long Lines. 
		if (i>=maxStyleLineLength) {
			state=SCE_MAKE_DEFAULT;
			styler.ColourTo(endPos, state);
			return(state);
		}
		
		/// style GNUMake Preproc
		if (currentPos==theStart && chCurr == '!') {
			state=SCE_MAKE_PREPROCESSOR;
			styler.ColourTo(endPos, state);
			return(state);
		}
		
		/// style GNUMake inline Comments
		if (chCurr == '#' && state==SCE_MAKE_DEFAULT) {
			state_prev=state;
			state=SCE_MAKE_COMMENT;
			ColourHere(styler, currentPos-1, state_prev);
			ColourHere(styler, endPos, state, SCE_MAKE_DEFAULT);
			return(state);
		}

		/// Style Target lines
		// Find a good position for a style stopper.
		if (currentPos>theStart && IsGraphic(chNext) 
			&& (strchr(" \t \"\' \\ /#!?&|+{}()[]<>;=,", (int)chCurr) != NULL)) {
			styleBreak=currentPos;
		}

		// skip identifier and target styling if this is a command line
		if (!line.bCommand && state==SCE_MAKE_DEFAULT) {
			if (chCurr == ':' && chNext != '=') {
				if(styleBreak>0 && styleBreak<currentPos && styleBreak>stylerPos) 
					ColourHere(styler, styleBreak, SCE_MAKE_DEFAULT, state);
				ColourHere(styler, currentPos-1, SCE_MAKE_TARGET, state);
			} else if (chCurr == ':' && chNext == '=') {
				// it's a ':=', so style as an identifier
				ColourHere(styler, currentPos-2, SCE_MAKE_IDENTIFIER, state);
			} else if (chCurr=='=' && chPrev != ':') {
					ColourHere(styler, currentPos-1, SCE_MAKE_IDENTIFIER, state);		
			}
		}

		/// lets signal a warning on unclosed Strings or Brackets.
		if (strchr("({", (int)chCurr)!=NULL) {
			ColourHere(styler, currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			line.iWarnEOL++;
		} else if (strchr(")}", (int)chCurr)!=NULL) {
			if (i>0) ColourHere(styler, currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			line.iWarnEOL--;
		}

		/// Style double quoted Strings
		if (line.inString && chCurr=='\"') {
			ColourHere(styler, currentPos-1, state);
			state=SCE_MAKE_STRING;
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state_prev);
			line.iWarnEOL--;
			line.inString = false;
		} else if	(!line.inString && chCurr=='\"') {
			state_prev = state;
			state = SCE_MAKE_DEFAULT;
			ColourHere(styler, currentPos-1, state_prev);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			line.inString=true;
			line.iWarnEOL++;
		}

		/// Style single quoted Strings. Don't EOL check for now.
		if (!line.inString && line.inSqString && chCurr=='\'') {
			ColourHere(styler, currentPos-1, state);
			state = SCE_MAKE_STRING;
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state_prev);
			line.inSqString = false;
		} else if	(!line.inString && !line.inSqString && chCurr=='\'') {
			state_prev = state;
			state = SCE_MAKE_DEFAULT;
			ColourHere(styler, currentPos-1, state_prev);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER, state);
			line.inSqString = true;
		}

		/// Style Keywords
		// ForwardSearch Searchstring.
		// Travels to the Future and retrieves Lottery draw results.
		std::string strSearch;

		// cpplusplus.com: any return values from IsAlphaNum (and co) >0 should be considered true.
		if (IsGraphic(chCurr) == 0) {
			startMark=0;
			strLen=0;
		}

		// got alphanumerics we mark the wordBoundary.
		if (IsAlpha(chCurr)>=1 && strLen == 0) {
			strLen++;
			startMark=i; // words relative start position (slineBuffer)
		} else if (strLen>0) {
			strLen++; // ... within a word dimension boundary.
		}

		// got the other End, copy the word:
		if (IsAlphaNum(chNext) == 0 && strLen > 0) {
			strSearch=slineBuffer.substr(startMark, strLen);
			startMark=currentPos-strLen+1; // words absolute position (styler)
			strLen=0;
		}

		// Ok, now we have some materia within our char buffer, so check whats in.
		// Do not match in Strings and the next char has to be either whitespace or ctrl.  
		if (state!=SCE_MAKE_STRING && strSearch.size()>0 && IsAlpha(chNext) == 0) {
			//Sci_PositionU wordLen=(Sci_PositionU)strSearch.size();

			// check if we get a match with Keywordlist externalCommands
			// Rule: preceeded by line start and AtStartChar() Ends on eol, whitespace or ;
			if (kwExtCmd.InList(strSearch.c_str())
				 && strchr("\t\r\n ;)", (int)chNext) !=NULL
				 &&  AtStartChar(styler, startMark-1)) {
				if (startMark > startLine && startMark >= stylerPos)
					styler.ColourTo(startMark-1, state);
				state_prev=state;
				state=SCE_MAKE_EXTCMD;
				ColourHere(styler, currentPos, state, SCE_MAKE_DEFAULT);
			} else if (state == SCE_MAKE_EXTCMD) {
				state=SCE_MAKE_DEFAULT;
				ColourHere(styler, currentPos, state);
			}

			// we now search for the word within the Directives Space.
			// Rule: preceeded by line start or .'='. Ends on eol, whitespace or ;
			if (kwGeneric.InList(strSearch.c_str())
					&& (strchr("\t\r\n ;)", (int)chNext) !=NULL)
					&& (startMark==theStart || styler.SafeGetCharAt( startMark-1) == '=')) {
				if (startMark > startLine && startMark >= stylerPos)
					styler.ColourTo(startMark-1, state);		
				state_prev=state;
				state=SCE_MAKE_DIRECTIVE;
				ColourHere(styler, currentPos, state, SCE_MAKE_DEFAULT);
			} else if (state == SCE_MAKE_DIRECTIVE) {
				state=SCE_MAKE_DEFAULT;
				ColourHere(styler,currentPos,state);
			}

			// ....and within functions $(sort,subst...) / used to style internal Variables too.
			// Rule: have to be prefixed by '(' and preceedet by whitespace or ;)
			if (kwFunctions.InList(strSearch.c_str())
					&& styler.SafeGetCharAt( startMark -2 ) == '$'
					&& styler.SafeGetCharAt( startMark -1 ) == '(') {
				if (startMark > startLine && startMark > stylerPos) 
					styler.ColourTo(startMark-1, state);
				state_prev = state;
				state = SCE_MAKE_FUNCTION;
				ColourHere(styler, currentPos, state, SCE_MAKE_DEFAULT);
			} else if (state == SCE_MAKE_FUNCTION) {
				state=SCE_MAKE_DEFAULT;
				ColourHere(styler, currentPos, state);
			}
			
			// Colour Strings which end with a Number
			if (IsNum(chCurr) && startMark > stylerPos && styler.SafeGetCharAt(startMark-1) != '-') {
				if (startMark>stylerPos) styler.ColourTo(startMark-1,state);
				ColourHere(styler, currentPos,  SCE_MAKE_NUMBER, SCE_MAKE_DEFAULT);
			}
			
			startMark=0;
			strLen=0;
			strSearch.clear();
		}

		/// Style User Variables Rule: $(...)
		if (chCurr == '$' && (strchr("{(", (int)chNext)!=NULL)) {
		  stylerPos =ColourHere(styler, currentPos-1, state);
			state_prev=state;
			state = SCE_MAKE_USER_VARIABLE;
		} else if (state == SCE_MAKE_USER_VARIABLE && (strchr("})", (int)chNext)!=NULL)) {
			if (state_prev==SCE_MAKE_USER_VARIABLE) state_prev = SCE_MAKE_DEFAULT;		
			ColourHere(styler, currentPos, state, state_prev);
			state = state_prev;
		}

		/// ... and $ based automatic Variables Rule: $@%<?^+*
		if (chCurr == '$' && (strchr("@%<?^+*", (int)chNext))!=NULL) {
			ColourHere(styler, currentPos-1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE && (strchr("@%<?^+*", (int)chCurr)!=NULL)) {
			ColourHere(styler, currentPos, state, state_prev);
			state = state_prev;
		}

		/// Style for automatic Variables. FluxCompensators orders: @%<^+'D'||'F'
		if ((strchr("@%<?^+*", (int)chCurr) >0) && (strchr("DF", (int)chNext)!=NULL)) {
			ColourHere(styler, currentPos-1, state);
			state_prev=state;
			state = SCE_MAKE_AUTOM_VARIABLE;
		} else if (state == SCE_MAKE_AUTOM_VARIABLE
				&& (strchr("@%<^+", (int)styler.SafeGetCharAt(currentPos-1))!=NULL
				    && (strchr("DF", (int)chCurr) !=NULL))) {
			ColourHere(styler, currentPos, state, state_prev);
			state = SCE_MAKE_DEFAULT;
		}

		/// Capture the Flags. Start match:  ( '-' ) or  (linestart + "-") or ("=-") Endmatch: (whitespace || EOL || "$./:\,'")
		if (( (AtStartChar(styler,currentPos)) && chNext=='-')
			|| (currentPos == theStart && chCurr == '-')) {
			state_prev=state;
			state = SCE_MAKE_FLAGS;
			bool j= (i>0 && (chCurr=='-') && chNext=='-') ? 1:0; // style both '-'
			if (currentPos-j > startLine) styler.ColourTo(currentPos-j, state_prev);
		} else if (state==SCE_MAKE_FLAGS && strchr("$\t\r\n /\\\",\''", (int)chNext) !=NULL) {
			ColourHere(styler, currentPos, state, state_prev);
			state = state_prev;
		}
		
		/// Operators..
		if (state==SCE_MAKE_DEFAULT && strchr("!?&|+[]<>;:=", (int)chCurr) != NULL && stylerPos <= currentPos) {
			ColourHere(styler, currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_OPERATOR, state);
		}
		
		/// Digits; _very_ simple for now.
		if(state==SCE_MAKE_DEFAULT && startMark==0 && IsNum(chCurr) && stylerPos <= currentPos)  {
			ColourHere(styler, currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_NUMBER, SCE_MAKE_DEFAULT);
		}

		i++;
	}
	
	if (line.iWarnEOL>0) {
		state=SCE_MAKE_IDEOL;
	} else if (line.iWarnEOL<1) {
		state=SCE_MAKE_DEFAULT;
	}

	ColourHere(styler, endPos, state, SCE_MAKE_DEFAULT);

	return(state);
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

	// check for continuation segments start
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


//
// Folding code from cMake, with small changes for bash scripts. 
//

static int calculateFoldMake(Sci_PositionU start, Sci_PositionU end, int foldlevel, Accessor &styler, bool bElse)
{
    // If the word is too long, it is not what we are looking for
    if ( end - start > 20 )
        return foldlevel;

    int newFoldlevel = foldlevel;

    char s[20]; // The key word we are looking for has atmost 13 characters
    for (unsigned int i = 0; i < end - start + 1 && i < 19; i++) {
        s[i] = static_cast<char>( styler[ start + i ] );
        s[i + 1] = '\0';
    }

    if ( CompareCaseInsensitive(s, "IF") == 0 || CompareCaseInsensitive(s, "IFEQ") == 0  || CompareCaseInsensitive(s, "IFNEQ") == 0 
				 ||CompareCaseInsensitive(s, "IFNDEF") == 0  || CompareCaseInsensitive(s, "WHILE") == 0
         || CompareCaseInsensitive(s, "MACRO") == 0 || CompareCaseInsensitive(s, "FOREACH") == 0
         || CompareCaseInsensitive(s, "ELSEIF") == 0   || CompareCaseInsensitive(s, "ELIF") == 0 )
        newFoldlevel++;
    else if ( CompareCaseInsensitive(s, "ENDIF") == 0 || CompareCaseInsensitive(s, "ENDWHILE") == 0
					|| CompareCaseInsensitive(s, "ENDMACRO") == 0 || CompareCaseInsensitive(s, "ENDFOREACH") == 0
					||  CompareCaseInsensitive(s, "FI") == 0)
        newFoldlevel--;
    else if ( bElse && CompareCaseInsensitive(s, "ELSEIF") == 0 )
        newFoldlevel++;
    else if ( bElse && CompareCaseInsensitive(s, "ELSE") == 0 )
        newFoldlevel++;

    return newFoldlevel;
}

static bool MakeNextLineHasElse(Sci_PositionU start, Sci_PositionU end, Accessor &styler)
{
    Sci_Position nNextLine = -1;
    for ( Sci_PositionU i = start; i < end; i++ ) {
        char cNext = styler.SafeGetCharAt( i );
        if ( cNext == '\n' ) {
            nNextLine = i+1;
            break;
        }
    }

    if ( nNextLine == -1 ) // We never foudn the next line...
        return false;

    for ( Sci_PositionU firstChar = nNextLine; firstChar < end; firstChar++ ) {
        char cNext = styler.SafeGetCharAt( firstChar );
        if ( cNext == ' ' )
            continue;
        if ( cNext == '\t' )
            continue;
        if ( styler.Match(firstChar, "ELSE")  || styler.Match(firstChar, "else"))
            return true;
        break;
    }

    return false;
}

static void FoldMakeDoc(Sci_PositionU startPos, Sci_Position length, int, WordList *[], Accessor &styler)
{
    // No folding enabled, no reason to continue...
    if ( styler.GetPropertyInt("fold") == 0 )
        return;

    bool foldAtElse = styler.GetPropertyInt("fold.at.else", 0) == 1;

    Sci_Position lineCurrent = styler.GetLine(startPos);
    Sci_PositionU safeStartPos = styler.LineStart( lineCurrent );

    bool bArg1 = true;
    Sci_Position nWordStart = -1;

    int levelCurrent = SC_FOLDLEVELBASE;
    if (lineCurrent > 0)
        levelCurrent = styler.LevelAt(lineCurrent-1) >> 16;
    int levelNext = levelCurrent;

    for (Sci_PositionU i = safeStartPos; i < startPos + length; i++) {
        char chCurr = styler.SafeGetCharAt(i);

        if ( bArg1 ) {
            if ( nWordStart == -1 && (IsAlphaNum(chCurr)) ) {
                nWordStart = i;
            }
            else if ( IsAlphaNum(chCurr) == false && nWordStart > -1 ) {
                int newLevel = calculateFoldMake( nWordStart, i-1, levelNext, styler, foldAtElse);

                if ( newLevel == levelNext ) {
                    if ( foldAtElse ) {
                        if ( MakeNextLineHasElse(i, startPos + length, styler) )
                            levelNext--;
                    }
                }
                else
                    levelNext = newLevel;
                bArg1 = false;
            }
        }

        if ( chCurr == '\n' ) {
            if ( bArg1 && foldAtElse) {
                if ( MakeNextLineHasElse(i, startPos + length, styler) )
                    levelNext--;
            }

            // If we are on a new line...
            int levelUse = levelCurrent;
            int lev = levelUse | levelNext << 16;
            if (levelUse < levelNext )
                lev |= SC_FOLDLEVELHEADERFLAG;
            if (lev != styler.LevelAt(lineCurrent))
                styler.SetLevel(lineCurrent, lev);

            lineCurrent++;
            levelCurrent = levelNext;
            bArg1 = true; // New line, lets look at first argument again
            nWordStart = -1;
        }
    }

    int levelUse = levelCurrent;
    int lev = levelUse | levelNext << 16;
    if (levelUse < levelNext)
        lev |= SC_FOLDLEVELHEADERFLAG;
    if (lev != styler.LevelAt(lineCurrent))
        styler.SetLevel(lineCurrent, lev);
}

static void ColouriseMakeDoc(Sci_PositionU startPos, Sci_Position length, int, WordList *keywords[], Accessor &styler) {
	
	int startStyle=SCE_MAKE_DEFAULT;
	std::string slineBuffer;

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
	
	maxStyleLineLength=styler.GetPropertyInt("max.style.linelength");
	maxStyleLineLength = ( maxStyleLineLength > 0) ? maxStyleLineLength : LEXMAKE_MAX_LINELEN;
			
	for (Sci_PositionU at = startPos; at < startPos + length; at++) {
		
		slineBuffer.resize(slineBuffer.size()+1);
		slineBuffer[linePos++] = styler[at];

		// End of line (or of max line buffer) met.
		if (styler[at] =='\n') {
			Sci_PositionU lineLength=GetLineLen(styler, at);
			if (lineLength==0) lineLength++;

			// Copy the remaining chars to the lineBuffer.
			// Todo: I dont like copying the whole line here.
			// It just isnt neccesary for the functionality and would help with memory usage on (very) long lines.
			if (lineLength != linePos)
				for (Sci_PositionU posi=linePos-1; posi<=lineLength; posi++){
					slineBuffer.resize(slineBuffer.size()+1);
					slineBuffer[posi]=styler[at++];
				}

			at=lineStart+lineLength-1;

			startStyle = ColouriseMakeLine(slineBuffer, lineLength, lineStart, at, keywords, styler, startStyle);
			slineBuffer.clear();
			lineStart = at+1;
			linePos=0;
		}
	}
	if (linePos>0){ // handle normal lines without an EOL mark.
		startStyle=ColouriseMakeLine(slineBuffer, linePos, lineStart, startPos+length-1, keywords, styler, startStyle);
		styler.ChangeLexerState(startPos, startPos+length); // Fini -> Request Screen redraw.
	}
}

static const char *const makefileWordListDesc[] = {
	"generica",
	"functions",
	"kwExtCmd",
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", FoldMakeDoc, makefileWordListDesc);