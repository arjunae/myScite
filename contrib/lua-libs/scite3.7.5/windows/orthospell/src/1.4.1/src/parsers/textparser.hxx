/*
 * parser classes for MySpell
 *
 * implemented: text, HTML, TeX
 *
 * Copyright (C) 2002, Laszlo Nemeth
 *
 */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Hunspell, based on MySpell.
 *
 * The Initial Developers of the Original Code are
 * Kevin Hendricks (MySpell) and Németh László (Hunspell).
 * Portions created by the Initial Developers are Copyright (C) 2002-2005
 * the Initial Developers. All Rights Reserved.
 *
 * Contributor(s): David Einstein, Davide Prina, Giuseppe Modugno,
 * Gianluca Turconi, Simon Brouwer, Noll János, Bíró Árpád,
 * Goldman Eleonóra, Sarlós Tamás, Bencsáth Boldizsár, Halácsy Péter,
 * Dvornik László, Gefferth András, Nagy Viktor, Varga Dániel, Chris Halls,
 * Rene Engelhard, Bram Moolenaar, Dafydd Jones, Harri Pitkänen
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#ifndef _TEXTPARSER_HXX_
#define _TEXTPARSER_HXX_

// set sum of actual and previous lines
#define MAXPREVLINE 4

#ifndef MAXLNLEN
#define MAXLNLEN 8192
#endif

#include "../hunspell/w_char.hxx"

/*
 * Base Text Parser
 *
 */

class TextParser {
 protected:
  int wordcharacters[256];           // for detection of the word boundaries
  char line[MAXPREVLINE][MAXLNLEN];  // parsed and previous lines
  char urlline[MAXLNLEN];            // mask for url detection
  int checkurl;
  int actual;  // actual line
  int head;    // head position
  int token;   // begin of token
  int state;   // state of automata
  int utf8;    // UTF-8 character encoding
  int next_char(char* line, int* pos);
  const w_char* wordchars_utf16;
  int wclen;

 public:
  TextParser();
  TextParser(const w_char* wordchars, int len);
  TextParser(const char* wc);
  void init(const char*);
  void init(const w_char* wordchars, int len);
  virtual ~TextParser();

  void put_line(char* line);
  char* get_line();
  char* get_prevline(int n);
  virtual char* next_token();
  virtual int change_token(const char* word);
  void set_url_checking(int check);

  int get_tokenpos();
  int is_wordchar(const char* w);
  inline int is_utf8() { return utf8; }
  const char* get_latin1(char* s);
  char* next_char();
  int tokenize_urls();
  void check_urls();
  int get_url(int token_pos, int* head);
  char* alloc_token(int token, int* head);
};

#endif
