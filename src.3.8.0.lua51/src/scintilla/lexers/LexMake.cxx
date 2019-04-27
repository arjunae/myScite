//Scintilla source code edit control
/**
 * @file LexMake.cxx
 * @author Neil Hodgson
 * @author Thorsten Kani(marcedo@HabMalneFrage.de)
 * @brief Lexer for make files
 * - Styles GNUMake Directives, internal function Keywords $(sort subst..) ,
 * - Automatic Variables $[@%<?^+*] , Flags "-" and Keywords for externalCommands
 * - Warns on unclosed Braces or doublequoted Strings.
 * - Handles multiLine Continuations & inlineComments and styles Strings and Numbers.
 * @brief 20.11.17 | fixEOF && cleanUp | Folding from cMake.
 * @brief 06.04.18 | fixErrEOL && Make and bash Style UserVars
 * @brief 07.05.18 | VC Flags, Convoluted UserVars, Code cleanUP && logging
 * @brief 20.02.19 | No need to backstep styler's Position on non multilined content.
 * @brief 10.03.19 | Fix doubleReferenced User vars $$() and automatic Vars, Improve logging.
 * @brief 14.03.19 | Style Variable Assignments denoted by = as identifiers. Prevent some possible Assertions.
 * @brief 26.03.19 | Allow multichar Automatic vars, only escape ControlChars in a Character Escape Sequence. Style Numbers better.
 * @brief 24.04.19 | Style other Stuff within Uservars, Improve line Continuations, Targets and code Docs.
 * @brief todos
 * : Wrap within a Class. 
 * @brief Copyright 1998-20?? by Neil Hodgson <neilh@scintilla.org>
 * The License.txt file describes the conditions under which this software may
 * be distributed.
 *
 */

#include <stdlib.h>
#include <string>
#include <string.h>
#include <vector> // debug (std::cout)
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>
#include <iostream>

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
// So use ~600kb as a maximum before simply style the rest in Defaults style.
#ifndef LEXMAKE_MAX_LINELEN
#define LEXMAKE_MAX_LINELEN 0606140
#endif
#ifdef LEX_MAX_LINELEN
#define LEXMAKE_MAX_LINELEN LEX_MAX_LINELEN
#endif

using namespace Scintilla;

// Holds LEXMAKE_MAX_LINELEN or property "lexer.makefile.line.chars.max" if it has been defined.
Sci_PositionU maxStyleLineLength;

static inline bool AtEOL(Accessor &styler, Sci_PositionU i) {
	return (styler[i] == '\n') ||
	  ((styler[i] == '\r') && (styler.SafeGetCharAt(i + 1) != '\n'));
}

static inline bool AtStartChar(const int ch) {
	if (strchr("$&|@\t\r\n \":;, '({})=", ch))
		return (1);
	
	return(0);
}

static inline bool IsNewline(const int ch) {
	return (ch == '\n' || ch == '\r');
}

// replacement functions because german umlauts ö Ü .. translate to negative values.
static inline int IsNum(const int ch) {
	if ((ch >= '0') && (ch <= '9'))
		return (1);
	
	return (0);
}

static inline int IsAlpha(const int ch) {
	if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z'))
		return (1);
	
	return (0);
}

static inline int IsAlphaNum(const int ch) {
	if (IsAlpha(ch) || IsNum(ch))
		return (1);
	
	return (0);
}

static inline int IsGraphic(const int ch) {
	if (ch>0) return (isgraph(ch));
	return (IsAlphaNum(ch));
}

static inline std::string opposite(const char ch) {
	std::string ret;
	if (ch == '(') ret= ')';
	if (ch == '[') ret= ']';
	if (ch == '{') ret= '}';
	return ret;
}

Sci_PositionU stylerPos; // Keep a Reference to the last styled Position.
Sci_PositionU styleEnd; // Additional sanity checking within ColourHere.

static inline unsigned int ColourHere(Accessor &styler, Sci_PositionU pos, unsigned int style1) {
	if (pos<stylerPos) return stylerPos;
	if (pos==(size_t)-1) return stylerPos;
	if (pos>styleEnd) return stylerPos;
	styler.ColourTo(pos, style1);
	stylerPos=pos;
	return (pos);
}

static inline unsigned int ColourHere(Accessor &styler, Sci_PositionU pos, unsigned int style1, unsigned int style2) {
	if (pos<stylerPos) return stylerPos;
	if (pos==(size_t)-1) return stylerPos;
	if (pos>styleEnd) return stylerPos;
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
	int startStyle,
	int iLog) {

	union { 
			struct { // remove that one- and have fun drinkin "Coffee".......
				int iWarnEOL;		// unclosed string / braces flag.
				bool bWarnSqStr;	// unclosed singleQuoted flag.
				bool bWarnDqStr;	// unclosed doubleQuoted flag.
				bool bWarnBrace;	// unclosed brace flag.
			} s;
	} line;line.s.iWarnEOL=0;line.s.bWarnBrace=0;line.s.bWarnDqStr=0;line.s.bWarnSqStr=0;line.s.bWarnBrace=0;

	Sci_PositionU i = 0; // primary line position counter
	Sci_PositionU styleBreak = 0; // Last control chars position.
	Sci_PositionU strLen = 0; // Keyword candidate length.
	Sci_PositionU startMark = 0; // Keyword candidates startPos. >0 while searching for a Keyword
	Sci_PositionU wordPrev = 0; // Last Words start position
	
	unsigned int state=(startStyle!=SCE_MAKE_IDEOL)?startStyle:SCE_MAKE_DEFAULT;
	unsigned int state_prev = SCE_MAKE_DEFAULT;
	bool bInCommand=false;		// true when a line begins with a tab (command)
	bool bInBashVar=false;		// true when in a Bash var.
	bool bStyleAsIdentifier=false;	// Style Identifiers in UserVars.
	
	std::string sInUserVar="";		// close convoluted User Variables at the correct brace.
	std::string sInBraces="";		// close open Braces at the matching counterpart.
	stylerPos=startLine;
	styleEnd=endPos;		// Another sanity check -just to make sure...
	
	/// Keywords
	WordList &kwGeneric = *keywordlists[0]; // Makefile->Directives
	WordList &kwFunctions = *keywordlists[1]; // Makefile->Functions (ifdef,define...)
	WordList &kwExtCmd = *keywordlists[2]; // Makefile->external Commands (mkdir,rm,attrib...)
	
	// Skip initial spaces and tabs for the current line. Spot that Position to check for later.
	while ((i < lengthLine) && isspacechar(styler.SafeGetCharAt(startLine+i)))
		i++;
	
	unsigned int theStart=startLine+i; // One Byte ought (not) to be enough for everyone....?
	
	// check for a tab character in column 0 indicating a command
	if ( styler.SafeGetCharAt(theStart-1) == '\t' ){
		bInCommand = true;
	}
	
	while ( i < lengthLine ) {
		Sci_PositionU currentPos=startLine+i;
		char chPrev=styler.SafeGetCharAt(currentPos-1);
		char chCurr=styler.SafeGetCharAt(currentPos);
		char chNext=styler.SafeGetCharAt(currentPos+1);
		
		/// Handle special Escaped Case \$$	
		std::string snippet;
		snippet+=styler.SafeGetCharAt(currentPos-2);
		snippet+=chPrev;
		snippet+=chCurr;
		snippet+=chNext;
		if((int)snippet.find("\\$$")!=-1) { // why not std::string::npos ?
			chPrev= ' '; chCurr=' '; chNext=' ';
		}
		
		/// Handle Character Escape Sequence - Except Hexadecimal Value or Path Representations.
		if (chPrev=='\\' && chCurr!='x' && strchr("\t\r\n \"\' \\ /#!?&|+{}()[]<>;=,", (int)chCurr)!= NULL ){
		  chCurr=' '; chNext=' ';
		}
		
		/// Handle (really) long Lines. 
		if (i>=maxStyleLineLength) {
			state=SCE_MAKE_DEFAULT;
			styler.ColourTo(endPos, state);
			return(state);
		}
		
		/// style GNUMake Preproc
		if (currentPos==theStart && chCurr == '!') {
			state=SCE_MAKE_PREPROCESSOR;
			styler.ColourTo(endPos-1, state);
			ColourHere(styler, endPos, SCE_MAKE_DEFAULT);
			state=SCE_MAKE_DEFAULT;
			return(state);
		}
		
		/// style GNUMake inline Comments
		if (chCurr == '#' && state==SCE_MAKE_DEFAULT) {
			state_prev=state;
			state=SCE_MAKE_COMMENT;
			ColourHere(styler, currentPos-1, state_prev);
			ColourHere(styler, endPos-1, state);
			ColourHere(styler, endPos, SCE_MAKE_DEFAULT);
			state=SCE_MAKE_DEFAULT;
			return(state);
		}
		
		/// Style Target lines
		// Find a good position for a style stopper. Directly use Scintillas Text buffer, so we can catch a newLine.
		if (currentPos>=theStart && IsGraphic(chNext) 
		&& (strchr(" \t \"\'\n #!?&|+{}()[]<>;=,", (int)chCurr) != NULL)) {
			styleBreak=currentPos;
		}
		
		/// Skip identifier and target styling if this is a command line
		if (!bInCommand && state==SCE_MAKE_DEFAULT) {			
			if (chCurr == ':' && chNext != '=') { // its a ':' so style as a target	
				if (styleBreak>0) ColourHere(styler, styleBreak, SCE_MAKE_DEFAULT);
				ColourHere(styler, currentPos-1, SCE_MAKE_TARGET, state);
			}	
		}
		
		/// Lets signal a warning on unclosed Braces. Check for the matching one.
		if ((state==SCE_MAKE_DEFAULT && sInBraces.size() && sInBraces.back()==chCurr)) {
			if (iLog) std::clog<< "[/NormalBrace] " << "\n"; 
			if (sInBraces.size()>0) sInBraces.resize(sInBraces.size()-1);
			if (sInBraces.size()==0) line.s.bWarnBrace=false;
		} else if (state==SCE_MAKE_DEFAULT && strchr("{(", (int)chCurr)!=NULL) {
			if (iLog) std::clog<< "[NormalBrace] " << "\n"; 
			sInBraces.append(opposite(chCurr));
			line.s.bWarnBrace=true;
		}
		
		/// Style single quoted Strings, exept word Hypens as "don't"
		if (state!=SCE_MAKE_STRING && line.s.bWarnSqStr && chCurr=='\'') {
			if (iLog) std::clog<< "[/SQString] " << "\n";
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER);
			state=state_prev;
			line.s.bWarnSqStr = false;
		} else if (state!=SCE_MAKE_STRING && chCurr=='\'') {
			if (iLog) std::clog<< "[SQString] " << "\n";
			state_prev = state;
			state = SCE_MAKE_IDENTIFIER;
			ColourHere(styler, currentPos-1, state_prev);
			ColourHere(styler, currentPos, state);
			line.s.bWarnSqStr=true;
		} 
		
		/// Style double quoted Strings.
		if (line.s.bWarnDqStr && chCurr=='\"' ) {
			if (iLog) std::clog<< "[/DQString] " << "\n";
			ColourHere(styler, currentPos, SCE_MAKE_STRING);
			state=state_prev;
			if(line.s.bWarnSqStr) state_prev=SCE_MAKE_DEFAULT;
			line.s.bWarnDqStr = false;
		} else if ((!line.s.bWarnDqStr) && chCurr=='\"') {
			if (iLog) std::clog<< "[DQString] " << "\n";
			state_prev = state;
			state = SCE_MAKE_STRING;
			ColourHere(styler, currentPos-1, state_prev);
			ColourHere(styler, currentPos, state);
			line.s.bWarnDqStr=true;
		}
		line.s.iWarnEOL=line.s.bWarnBrace || line.s.bWarnDqStr || line.s.bWarnSqStr;
		
		if (iLog>0) {
			std::clog << i << "	" << chCurr<<"	";
			std::clog << (line.s.iWarnEOL); 
			std::clog << (line.s.bWarnBrace);
			std::clog << (line.s.bWarnDqStr);
			std::clog<< (line.s.bWarnSqStr);
			std::clog << "\n";
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
		if ((IsAlphaNum(chNext) == 0 && strchr("-_", (int)chNext) == NULL ) && strLen > 0) {
			strSearch=slineBuffer.substr(startMark, strLen);
			wordPrev=startLine+startMark;
			startMark=currentPos-strLen+1; // words absolute position (styler)
			strLen=0;
		}
		
		// Ok, now we have some materia within our char buffer, so check whats in.
		// Do not match in Strings and the next char has to be either whitespace or ctrl.
		if (state!=SCE_MAKE_STRING && strSearch.size()>0 && IsAlpha(chNext)==0) {
			//Sci_PositionU wordLen=(Sci_PositionU)strSearch.size();
			
			// we now search for the word within the Directives Space.
			// Rule: preceeded by line start or '=' || '.' Ends on eol, whitespace or ;
			if (kwGeneric.InList(strSearch.c_str()) &&
			(theStart==startMark || strchr(".=",(int)styler.SafeGetCharAt(startMark -1))!=NULL)
			&& (strchr("\t\r\n ;)", (int)chNext) !=NULL)) {
				if (iLog) std::clog<< "[/Directive] " << strSearch << "\n";
				if (startMark > startLine) ColourHere(styler, startMark-1, state);
				ColourHere(styler, currentPos, SCE_MAKE_DIRECTIVE);
			}
			
			// ....and within functions $(sort,subst...) / used to style internal Variables too.
			// Rule: have to be prefixed by '$('
			if (kwFunctions.InList(strSearch.c_str())
			&& styler.SafeGetCharAt( startMark -2 ) == '$' && styler.SafeGetCharAt(startMark -1 ) == '(') {
				if (iLog) std::clog<< "[/Function] " << strSearch << "\n";
				if (startMark > startLine) ColourHere(styler, startMark-1, state);
				ColourHere(styler, currentPos, SCE_MAKE_FUNCTION);
			}
			
			// check if we get a match with Keywordlist externalCommands
			// Rule: preceeded by line start and AtStartChar() Ends on eol, whitespace or ;
			if (kwExtCmd.InList(strSearch.c_str())
			&& strchr("\t\r\n ; \\)", (int)chNext) !=NULL 
			&& AtStartChar(styler.SafeGetCharAt(startMark-1))) {
				if (iLog) std::clog<< "[/extCMD] " << strSearch << "\n";
				if (startMark > startLine) ColourHere(styler, startMark-1, state);
				ColourHere(styler, currentPos, SCE_MAKE_EXTCMD);
			}
			
			// Colour Strings which end with a Number
			if (state==SCE_MAKE_DEFAULT && IsNum(chCurr) && startMark >= stylerPos) {
				ColourHere(styler, startMark-1, state);
				ColourHere(styler, currentPos, SCE_MAKE_NUMBER);
			}
			
			startMark=0;
			strLen=0;
			strSearch.clear();
		}
		
		/// Colour Variable Assignments which end with a =
		if ((state==SCE_MAKE_DEFAULT) && chNext=='=') {
			ColourHere(styler, wordPrev-1, SCE_MAKE_DEFAULT);
			ColourHere(styler, currentPos, SCE_MAKE_IDENTIFIER);
			state=SCE_MAKE_DEFAULT;
		}
		
		/// Capture the Flags. Start match: ( '-' || '//' ) Endmatch: (whitespace || EOL || "$/;\')]}")
		if ((state==SCE_MAKE_DEFAULT || state==SCE_MAKE_USER_VARIABLE) && AtStartChar(chPrev)
		&& ((chCurr=='-') || (chPrev != ':' && chCurr == '/' && chNext == '/'))) {
			if (iLog) std::clog<< "[Flags] " << "\n";
			ColourHere(styler,currentPos-1, state);
			if(state!=SCE_MAKE_FLAGS) state_prev=state;
			state=SCE_MAKE_FLAGS;
			ColourHere(styler,currentPos, state);
		}
		if (state==SCE_MAKE_FLAGS && strchr(" \r\n$;\\\"\')]}", (int)chNext) != NULL) {
			ColourHere(styler, currentPos, state);
			state=state_prev;
			if (iLog) std::clog<< "[/Flags] " << "\n";
		}
		
		/// Style Bash Vars $STRING / $$String. Automatic vars will be styled separately.
		if (chCurr == '$' && chNext!='$' && strchr("{([@%<?^+|* \t\'\"", (int)chNext)==NULL) {
			// Style the prefix
			if (iLog) std::clog<< "[BashVar] " << "\n";
			if(state!=SCE_MAKE_USER_VARIABLE) state_prev=state;
			int offset = (chPrev=='$')?1:0;
			stylerPos=ColourHere(styler, currentPos-1-offset, state);
			stylerPos=ColourHere(styler, currentPos+offset, SCE_MAKE_USER_VARIABLE);
			bInBashVar=true;
		} else if (bInBashVar && (strchr(" \t\'\"\\#!?&|+;,(){}", (int)chNext)!=NULL)) {
			ColourHere(styler, currentPos, SCE_MAKE_USER_VARIABLE);
			state=state_prev;
			if (line.s.iWarnEOL) state_prev=SCE_MAKE_DEFAULT; // Exception for Quotes
			bInBashVar=false;
			if (iLog) std::clog<< "[/BashVar] " << "\n";
		} else if (bInBashVar) {
			ColourHere(styler, currentPos, SCE_MAKE_USER_VARIABLE);
		}
		
		/// ... $ prefixed or DF suffixed automatic Variables. FluxCompensators orders: ($)@%<^+|*'D'||'F'
		if (((chCurr=='$' && strchr("@%<?^+|*", (int)chNext)>0) 
		|| ( strchr("@%<?^+*", (int)chCurr) >0 && strchr("DF", (int)chNext)!=NULL))) {
			if (iLog) std::clog<< "[AutomaticVar] " << "\n";
			ColourHere(styler, currentPos-1, state);
			state_prev=state;
			state=SCE_MAKE_EXTCMD;
			ColourHere(styler, currentPos, state);
		} else if (state == SCE_MAKE_EXTCMD && (strchr("@%<^+|*DF", (int)chNext) == NULL)) {
			ColourHere(styler, currentPos, SCE_MAKE_EXTCMD, SCE_MAKE_DEFAULT);
			if (line.s.iWarnEOL || sInUserVar.size()) state_prev=SCE_MAKE_DEFAULT; // Exception for Quotes
			state=state_prev;
			if (iLog) std::clog<< "[/AutomaticVar] " << "\n";
		} else if (state == SCE_MAKE_EXTCMD && (strchr("@%<^+|*DF", (int)chCurr) != NULL)) {
			ColourHere(styler, currentPos, state);
		}
		
		/// ... Style User Variables Rule: $(...) and doubleReferences $$(())
		if (!bInBashVar && (chPrev=='$' || chCurr == '$') && strchr("{([", (int)chNext)!=NULL ) {
			if (iLog) std::clog<< "[UserVar: '" << sInUserVar << "']\n";
			bStyleAsIdentifier=false;
			// Opening Brace -Style the prefix '$('
			int offset = (chPrev=='$')?1:0;
			ColourHere(styler, currentPos-1-offset, state);
			ColourHere(styler, currentPos, SCE_MAKE_USER_VARIABLE);
			ColourHere(styler, currentPos+1, SCE_MAKE_USER_VARIABLE);
			if(state!=SCE_MAKE_USER_VARIABLE) state_prev=state;
			state=SCE_MAKE_USER_VARIABLE;
		} else if(sInUserVar.size() && sInUserVar.back()!=chCurr) {
			if (strchr("${([", (int)chCurr)!=NULL) ColourHere(styler, currentPos, SCE_MAKE_USER_VARIABLE);
			// Readability Exception: Style Identifier, SingleQuotes, Keywords and Flags in UserVars.
		 	if (strchr(" \t /#!?&|+;,", (int)chCurr)!=NULL) bStyleAsIdentifier=true;
			if (bStyleAsIdentifier && !line.s.bWarnSqStr && startMark==0 && state!=SCE_MAKE_FLAGS)
				ColourHere(styler, currentPos, SCE_MAKE_DEFAULT);
		} else if (sInUserVar.size() && (sInUserVar.back()==chCurr || currentPos==endPos)) {
			// Closing Brace found
			if (iLog) std::clog<< "[/UserVar: '" << sInUserVar << "']\n";
			ColourHere(styler, currentPos, SCE_MAKE_USER_VARIABLE);
			if (sInUserVar.size()>0) sInUserVar.resize(sInUserVar.size()-1);
			if (sInUserVar.size()==0 || currentPos==endPos) {
			// Final Brace - Close User Var.
				state=SCE_MAKE_DEFAULT;
				// Workaround for UserVars in Strings.	
				if (line.s.bWarnDqStr) state=SCE_MAKE_STRING;
				if (line.s.bWarnDqStr || line.s.bWarnSqStr ) state_prev=SCE_MAKE_DEFAULT;
				bStyleAsIdentifier=false;
			}
			if(currentPos==endPos){
				state=SCE_MAKE_DEFAULT;
				ColourHere(styler, currentPos, state);
			}
		}
		
		/// ... Store chNext to close the correct brace later.
		if (!bInBashVar && state==SCE_MAKE_USER_VARIABLE && chCurr!='$' ) {
				sInUserVar.append(opposite(chCurr));
		}
		
		/// Operators..
		if (state==SCE_MAKE_DEFAULT && strchr("!?&|+<>;:=", (int)chCurr) != NULL && stylerPos < currentPos) {
			ColourHere(styler, currentPos-1, state);
			ColourHere(styler, currentPos, SCE_MAKE_OPERATOR, state);
		}
		
		/// Numbers and simple Versioning using '.' || '-'
		if(state==SCE_MAKE_DEFAULT && startMark==0 && IsNum(chCurr)) {
			ColourHere(styler, currentPos-1, state);
			state=SCE_MAKE_NUMBER;
			ColourHere(styler, currentPos, SCE_MAKE_NUMBER, SCE_MAKE_DEFAULT);
		}
		if (state==SCE_MAKE_NUMBER && (AtStartChar(chNext) || IsAlpha(chNext)) ) {
			ColourHere(styler, currentPos, SCE_MAKE_NUMBER);
			state=SCE_MAKE_DEFAULT;
		} else if (state==SCE_MAKE_NUMBER && (IsNum(chCurr) || chCurr=='.' || chCurr=='-' )) {
			ColourHere(styler, currentPos, state);
		}
		
		i++;
	}
	
 	if (line.s.iWarnEOL>0) 
		state=SCE_MAKE_IDEOL;
	else if(state==SCE_MAKE_IDEOL && line.s.iWarnEOL==0)
		state=SCE_MAKE_DEFAULT;
	
	ColourHere(styler, endPos, state);
	return(state);
}

/**
// @brief returns a multilines startPosition or current position
// if the Offset does not belong to a Multiline Segment.
**/
static int GetMLineStart(Accessor &styler, Sci_Position start) {

	int status=0; // 1=cont_end 2=cont_middle/start
	Sci_Position currMLSegment=0;
	Sci_Position prevMLSegment=0;
	Sci_Position finalMLSegment=0;

	// check if current lines last visible char is a continuation
	Sci_Position position=start;
	// moves to last visible char
	while (styler[position++]!='\n');
	while (IsGraphic(styler.SafeGetCharAt(--position)==0)) ;
	position--;
	if (styler[position]=='\\') {
		status=2;
	} else {
		status=1;
		finalMLSegment=start;
	}

	// check for continuation segments start
	position = styler.LineStart(styler.GetLine(position)-1);
	while (position != currMLSegment) {
		currMLSegment=position;
		while (styler[++position]!='\n');
		if ((status==2) && (styler[position+1]=='\r' || styler[position+1]=='\n'))
			break; // empty line reached
		while (iscntrl(styler.SafeGetCharAt(--position)));
		position--;
		if (styler[position]!='\\' && styler[position+1]!='\\') {
			if (status==1) {
				currMLSegment=finalMLSegment;
				break; // no MultiLine
			} else {
				currMLSegment=prevMLSegment;
				break; // firstSegment reached.
			}
		} else { // continue search
			prevMLSegment=styler.LineStart(styler.GetLine(position));
			position = styler.LineStart(styler.GetLine(position)-1);
			status=2;
		}
	}
	return (currMLSegment);
}

/**
// @brief returns a multilines length or current lines length
// if the Position does not belong to a Multiline Segment.
**/
static int GetLineLen(Accessor &styler, Sci_Position start) {
	Sci_PositionU length=0;
	Sci_Position counter=start;

	// Check for an empty Line.
	while (counter>0 && IsNewline(styler[--counter])) {
		if (styler[counter]=='\n') return (start-counter); // empty Line
	}
	
	// Skip any space chars before the newlines.
	if(IsASpaceOrTab(styler[counter])){
		while (IsASpaceOrTab(styler[counter--]));
		counter++;
	}

	// check that next char for beeing a continuation
	if (styler[counter]=='\\') {
		// ..rewind further to current lines startpos
		while (counter>=0 && !IsNewline(styler[--counter]));

		// ...get continued lines length
		while (true) {
			//..forward to Segments lineEnd
			while (styler[counter++]) {
				length++;
				if (styler[counter]=='\n' || styler[counter]=='\0') break;
			}

			// Handle Line Continuations
			// cope with unix and windows style line ends and spaces.
			if (styler[counter]=='\n') {
				counter=(styler[counter-1]=='\r')?counter-2:counter-1; // rewind newlines
				while (IsASpaceOrTab(styler[counter])) counter--; // rewind spaces
				if (!(styler[counter]=='\\')) { 
					return (length); // Continuation end reached. 
					break;
				} else {
					while (!(styler[counter]=='\n')) counter++; // Continuation.
				}
			} else if (styler[counter]=='\0') {
				return (length-1); // handle continuated lines without an EOL mark.
				break;
			}
		}
	} else {
		// Handle lines without an EOL Marker.
		if (styler[counter]!='\n')
			while (counter>=0 && styler[--counter]!='\n');

		return (start-counter);
	}

	return (start-counter);
}

//
// Folding code from cMake, with small changes for bash scripts. 
//
static int calculateFoldMake(Sci_PositionU start, Sci_PositionU end, int foldlevel, Accessor &styler)
{
	// If the word is >"= Chars, it's not what we are looking for.
	if ( end - start > 20 )
		return foldlevel;

	int newFoldlevel = foldlevel;
	char s[20]; // The key word we are looking for has atmost 13 characters
	for (unsigned int i = 0; i < end - start + 1 && i < 19; i++) {
		s[i] = static_cast<char>( styler[ start + i ] );
		s[i + 1] = '\0';
 }

	if ( CompareCaseInsensitive(s, "IF") == 0 || CompareCaseInsensitive(s, "IFEQ") == 0 || CompareCaseInsensitive(s, "IFNEQ") == 0
	|| CompareCaseInsensitive(s, "IFNDEF") == 0 || CompareCaseInsensitive(s, "WHILE") == 0 || CompareCaseInsensitive(s, "MACRO") == 0
	|| CompareCaseInsensitive(s, "FOREACH") == 0 || CompareCaseInsensitive(s, "FOR") == 0)
		newFoldlevel++;
	else if ( CompareCaseInsensitive(s, "ENDIF") == 0 || CompareCaseInsensitive(s, "ENDWHILE") == 0
	|| CompareCaseInsensitive(s, "ENDMACRO") == 0 || CompareCaseInsensitive(s, "ENDFOREACH") == 0 || CompareCaseInsensitive(s, "ENDFOR") == 0
	|| CompareCaseInsensitive(s, "FI") == 0 || CompareCaseInsensitive(s, "DONE") == 0)
		newFoldlevel--;
 
	// if ( bElse && (CompareCaseInsensitive(s, "ELSEIF") == 0 
	//	|| CompareCaseInsensitive(s, "ELIF") == 0)|| CompareCaseInsensitive(s, "ELSE") == 0))
	//newFoldlevel++;

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
	if ( nNextLine == -1 ) // We never found the next Line.
	return false;

	for ( Sci_PositionU firstChar = nNextLine; firstChar < end; firstChar++ ) {
		char cNext = styler.SafeGetCharAt( firstChar );
		if ( cNext == ' ' ) continue;
		if ( cNext == '\t' ) continue;
		if ( styler.Match(firstChar, "ELSE") || styler.Match(firstChar, "else")) return true;
		break;
	}

 return false;
}

static void FoldMakeDoc(Sci_PositionU startPos, Sci_Position length, int, WordList *[], Accessor &styler)
{
	// No folding enabled, no reason to continue...
	if ( styler.GetPropertyInt("fold") == 0 )
	return;

	bool foldAtElse =0; // styler.GetPropertyInt("fold.at.else", 0) == 1;

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
			} else if ( IsAlphaNum(chCurr) == false && nWordStart > -1 ) {
				int newLevel = calculateFoldMake( nWordStart, i-1, levelNext, styler);
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

static void ColouriseMakeDoc(Sci_PositionU startPos, Sci_Position length, int startStyle, WordList *keywords[], Accessor &styler) {
	std::string slineBuffer;
	Sci_PositionU o_startPos;
	
	int iLog=0; // choose to enable Verbosity. Requires a bash shell on windows.
	if (iLog>0) std::clog << "---------\n"<<"[Pos]	[Char]	[WarnEOLState]\n";
	//styler.Flush();
	// For efficiency reasons, scintilla calls the lexer with the cursors current position and a reasonable length.
	// If that Position is within a continued Multiline, we notify the start position of that Line to Scintilla here:
	// find a MultiLines start, reset styler Position
	o_startPos=GetMLineStart(styler, startPos);
	if (o_startPos!=startPos){
		styler.StartSegment(o_startPos);
		styler.StartAt(o_startPos);
		length=length+(startPos-o_startPos);
		startPos=o_startPos;
		startStyle=styler.StyleAt(startPos-1);
	} else {
		styler.StartSegment(startPos);
		styler.StartAt(startPos);
	}
		startStyle=styler.StyleAt(startPos-1);
	Sci_PositionU linePos = 0;
	Sci_PositionU lineStart = startPos;
	
	maxStyleLineLength=styler.GetPropertyInt("lexer.makefile.line.chars.max");
	maxStyleLineLength = (maxStyleLineLength > 0) ? maxStyleLineLength : LEXMAKE_MAX_LINELEN;
	
	for (Sci_PositionU at = startPos; at < startPos + length; at++) {
		// Use a second buffer for keyword matching.
		slineBuffer.resize(slineBuffer.size()+1);
		slineBuffer[linePos++] = styler[at];
		
		// End of line (or of max line buffer) met.
		if (styler[at] =='\n') {
			Sci_PositionU lineLength=GetLineLen(styler, at);
			if (lineLength==0) lineLength++;
			
			// Copy the remaining chars to the lineBuffer.
			if (lineLength != linePos)
				for (Sci_PositionU posi=linePos-1; posi<=lineLength; posi++){
					slineBuffer.resize(slineBuffer.size()+1);
					slineBuffer[posi]=styler[at++];
				}
			at=lineStart+lineLength-1;
			startStyle = ColouriseMakeLine(slineBuffer, lineLength, lineStart, at, keywords, styler, startStyle, iLog);
			slineBuffer.clear();
			lineStart = at+1;
			linePos=0;
			}
	}
	if (linePos>0){ // handle the (continuated) line
		startStyle=ColouriseMakeLine(slineBuffer, linePos, lineStart, startPos+length-1, keywords, styler, startStyle, iLog);
	}
	if (iLog)  std::clog.flush();
}

static const char *const makefileWordListDesc[] = {
	"Make Directive Keywords",
	"Make Function Keywords",
	"External Command Keywords",
	0
};

LexerModule lmMake(SCLEX_MAKEFILE, ColouriseMakeDoc, "makefile", FoldMakeDoc, makefileWordListDesc);
