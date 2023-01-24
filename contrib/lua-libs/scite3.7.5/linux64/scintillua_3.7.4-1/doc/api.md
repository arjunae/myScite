<a id="Scintillua"></a>
# Scintillua

- - -

## Overview

The Scintillua Scintilla lexer has its own API to avoid any modifications to
Scintilla itself. It is invoked using [`SCI_PRIVATELEXERCALL`][]. Please note
that some of the names of the API calls do not make perfect sense. This is a
tradeoff in order to keep Scintilla unmodified.

[`SCI_PRIVATELEXERCALL`]: http://scintilla.org/ScintillaDoc.html#LexerObjects

The following notation is used:

    SCI_PRIVATELEXERCALL (int operation, void *pointer)

This means you would call Scintilla like this:

    SendScintilla(sci, SCI_PRIVATELEXERCALL, operation, pointer);


<a id="Scintillua.Scintillua.Usage.Example"></a>

## Scintillua Usage Example

Here is a pseudo-code example:

    init_app() {
      sci = scintilla_new()
      lib = "/home/mitchell/app/lexers/liblexlpeg.so"
      SendScintilla(sci, SCI_LOADLEXERLIBRARY, 0, lib)
    }

    create_doc() {
      doc = SendScintilla(sci, SCI_CREATEDOCUMENT)
      SendScintilla(sci, SCI_SETDOCPOINTER, 0, doc)
      SendScintilla(sci, SCI_SETLEXERLANGUAGE, 0, "lpeg")
      home = "/home/mitchell/app/lexers"
      SendScintilla(sci, SCI_SETPROPERTY, "lexer.lpeg.home", home)
      SendScintilla(sci, SCI_SETPROPERTY, "lexer.lpeg.color.theme", "light")
      fn = SendScintilla(sci, SCI_GETDIRECTFUNCTION)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETDIRECTFUNCTION, fn)
      psci = SendScintilla(sci, SCI_GETDIRECTPOINTER)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, psci)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, "lua")
    }

    set_lexer(lang) {
      psci = SendScintilla(sci, SCI_GETDIRECTPOINTER)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, psci)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, lang)
    }

## Functions defined by `Scintillua`

<a id="SCI_CHANGELEXERSTATE"></a>
### `SCI_PRIVATELEXERCALL` (SCI\_CHANGELEXERSTATE, lua)

Tells Scintillua to use `lua` as its Lua state instead of creating a separate
state.

`lua` must have already opened the "base", "string", "table", "package", and
"lpeg" libraries. If `lua` is a Lua 5.1 state, it must have also opened the
"io" library.

Scintillua will create a single `lexer` package (that can be used with Lua's
`require()`), as well as a number of other variables in the
`LUA_REGISTRYINDEX` table with the "sci_" prefix.

Instead of including the path to Scintillua's lexers in the `package.path` of
the given Lua state, set the "lexer.lpeg.home" property appropriately
instead. Scintillua uses that property to find and load lexers.

Fields:

* `SCI_CHANGELEXERSTATE`: 
* `lua`: (`lua_State *`) The Lua state to use.

Usage:

* `lua = luaL_newstate()`
* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_CHANGELEXERSTATE, lua)`

<a id="SCI_GETDIRECTFUNCTION"></a>
### `SCI_PRIVATELEXERCALL` (SCI\_GETDIRECTFUNCTION, SciFnDirect)

Tells Scintillua the address of the function that handles Scintilla messages.

Despite the name `SCI_GETDIRECTFUNCTION`, it only notifies Scintillua what
the value of `SciFnDirect` obtained from [`SCI_GETDIRECTFUNCTION`][] is. It
does not return anything.
Use this if you would like to have the Scintillua lexer set all Lua LPeg
lexer styles automatically. This is useful for maintaining a consistent color
theme. Do not use this if your application maintains its own color theme.

If you use this call, it *must* be made *once* for each Scintilla buffer that
was created using [`SCI_CREATEDOCUMENT`][]. You must also use the
[`SCI_SETDOCPOINTER()`](#SCI_SETDOCPOINTER) Scintillua API call.

[`SCI_GETDIRECTFUNCTION`]: http://scintilla.org/ScintillaDoc.html#SCI_GETDIRECTFUNCTION
[`SCI_CREATEDOCUMENT`]: http://scintilla.org/ScintillaDoc.html#SCI_CREATEDOCUMENT

Fields:

* `SCI_GETDIRECTFUNCTION`: 
* `SciFnDirect`: The pointer returned by [`SCI_GETDIRECTFUNCTION`][].

Usage:

* `fn = SendScintilla(sci, SCI_GETDIRECTFUNCTION)`
* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETDIRECTFUNCTION, fn)`

See also:

* [`SCI_SETDOCPOINTER`](#SCI_SETDOCPOINTER)

<a id="SCI_GETLEXERLANGUAGE"></a>
### `SCI_PRIVATELEXERCALL` (SCI\_GETLEXERLANGUAGE, languageName)

Returns the length of the string name of the current Lua LPeg lexer or stores
the name into the given buffer. If the buffer is long enough, the name is
terminated by a `0` character.

For parent lexers with embedded children or child lexers embedded into
parents, the name is in "lexer/current" format, where "lexer" is the actual
lexer's name and "current" is the parent or child lexer at the current caret
position. In order for this to work, you must have called
[`SCI_GETDIRECTFUNCTION`](#SCI_GETDIRECTFUNCTION) and
[`SCI_SETDOCPOINTER`](#SCI_SETDOCPOINTER).

Fields:

* `SCI_GETLEXERLANGUAGE`: 
* `languageName`: (`char *`) If `0`, returns the length that should be
  allocated to store the string Lua LPeg lexer name. Otherwise fills the
  buffer with the name.

<a id="SCI_GETSTATUS"></a>
### `SCI_PRIVATELEXERCALL` (SCI\_GETSTATUS)

Returns the error message of the Scintillua or Lua LPeg lexer error that
occurred (if any).

If no error occurred, the returned message will be empty.

Since Scintillua does not throw errors as they occur, errors can only be
handled passively. Note that Scintillua does print all errors to stderr.

Fields:

* `SCI_GETSTATUS`: 

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETSTATUS, errmsg)`
* `if (strlen(errmsg) > 0) { /* handle error */ }`

<a id="SCI_PRIVATELEXERCALL"></a>
### `SCI_PRIVATELEXERCALL` (styleNum, style)

Depending on the sign of `styleNum`, returns the length of the associated
string for the given style number or stores the string into the given buffer.
If the buffer is long enough, the string is terminated by a `0` character.

For negative `styleNum`, the associated string is a SciTE-formatted style
definition. Otherwise, the associated string is the name of the token for the
given style number.

Please see the [SciTE documentation][] for the style definition format
specified by `style.*.stylenumber`. You can parse these definitions to set
Lua LPeg lexer styles manually if you chose not to have them set
automatically using the [`SCI_GETDIRECTFUNCTION()`](#SCI_GETDIRECTFUNCTION)
and [`SCI_SETDOCPOINTER()`](#SCI_SETDOCPOINTER) Scintillua API calls.

[SciTE documentation]: http://scintilla.org/SciTEDoc.html

Fields:

* `styleNum`: (`int`) For the range `-STYLE_MAX <= styleNum < 0`, uses the
  Scintilla style number `-styleNum - 1` for returning SciTE-formatted style
  definitions. (Style `0` would be `-1`, style `1` would be `-2`, and so on.)
  For the range `0 <= styleNum < STYLE_MAX`, uses the normal Scintilla style
  number for returning token names.
* `style`: (`char *`) If `0`, returns the length that should be allocated
  to store the associated string. Otherwise fills the buffer with the string.

Usage:

* `style = SendScintilla(sci, SCI_GETSTYLEAT, pos)`
* `SendScintilla(sci, SCI_PRIVATELEXERCALL, style, token)`
* `// token now contains the name of the style at pos`

<a id="SCI_SETDOCPOINTER"></a>
### `SCI_PRIVATELEXERCALL` (SCI\_SETDOCPOINTER, sci)

Tells Scintillua the address of the Scintilla window currently in use.

Despite the name `SCI_SETDOCPOINTER`, it has no relationship to Scintilla
documents.

Use this call only if you are using the
[`SCI_GETDIRECTFUNCTION()`](#SCI_GETDIRECTFUNCTION) Scintillua API call. It
*must* be made *before* each call to the
[`SCI_SETLEXERLANGUAGE()`](#SCI_SETLEXERLANGUAGE) Scintillua API call.

Fields:

* `SCI_SETDOCPOINTER`: 
* `sci`: The pointer returned by [`SCI_GETDIRECTPOINTER`][].

[`SCI_GETDIRECTPOINTER`]: http://scintilla.org/ScintillaDoc.html#SCI_GETDIRECTPOINTER

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, sci)`

See also:

* [`SCI_GETDIRECTFUNCTION`](#SCI_GETDIRECTFUNCTION)
* [`SCI_SETLEXERLANGUAGE`](#SCI_SETLEXERLANGUAGE)

<a id="SCI_SETLEXERLANGUAGE"></a>
### `SCI_PRIVATELEXERCALL` (SCI\_SETLEXERLANGUAGE, languageName)

Sets the current Lua LPeg lexer to `languageName`.

If you are having the Scintillua lexer set the Lua LPeg lexer styles
automatically, make sure you call the
[`SCI_SETDOCPOINTER()`](#SCI_SETDOCPOINTER) Scintillua API *first*.

Fields:

* `SCI_SETLEXERLANGUAGE`: 
* `languageName`: (`const char*`) The name of the Lua LPeg lexer to use.

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, "lua")`

See also:

* [`SCI_SETDOCPOINTER`](#SCI_SETDOCPOINTER)


- - -

<a id="lexer"></a>
# The `lexer` Module

- - -

Lexes Scintilla documents with Lua and LPeg.


<a id="lexer.Overview"></a>

## Overview

Lexers highlight the syntax of source code. Scintilla (the editing component
behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
lexers which are notoriously difficult to create and/or extend. On the other
hand, Lua makes it easy to to rapidly create new lexers, extend existing
ones, and embed lexers within one another. Lua lexers tend to be more
readable than C++ lexers too.

Lexers are Parsing Expression Grammars, or PEGs, composed with the Lua
[LPeg library][]. The following table comes from the LPeg documentation and
summarizes all you need to know about constructing basic LPeg patterns. This
module provides convenience functions for creating and working with other
more advanced patterns and concepts.

Operator             | Description
---------------------|------------
`lpeg.P(string)`     | Matches `string` literally.
`lpeg.P(`_`n`_`)`    | Matches exactly _`n`_ characters.
`lpeg.S(string)`     | Matches any character in set `string`.
`lpeg.R("`_`xy`_`")` | Matches any character between range `x` and `y`.
`patt^`_`n`_         | Matches at least _`n`_ repetitions of `patt`.
`patt^-`_`n`_        | Matches at most _`n`_ repetitions of `patt`.
`patt1 * patt2`      | Matches `patt1` followed by `patt2`.
`patt1 + patt2`      | Matches `patt1` or `patt2` (ordered choice).
`patt1 - patt2`      | Matches `patt1` if `patt2` does not match.
`-patt`              | Equivalent to `("" - patt)`.
`#patt`              | Matches `patt` but consumes no input.

The first part of this document deals with rapidly constructing a simple
lexer. The next part deals with more advanced techniques, such as custom
coloring and embedding lexers within one another. Following that is a
discussion about code folding, or being able to tell Scintilla which code
blocks are "foldable" (temporarily hideable from view). After that are
instructions on how to use LPeg lexers with the aforementioned Textadept and
SciTE editors. Finally there are comments on lexer performance and
limitations.

[LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Textadept]: http://foicica.com/textadept
[SciTE]: http://scintilla.org/SciTE.html


<a id="lexer.Lexer.Basics"></a>

## Lexer Basics

The *lexers/* directory contains all lexers, including your new one. Before
attempting to write one from scratch though, first determine if your
programming language is similar to any of the 80+ languages supported. If so,
you may be able to copy and modify that lexer, saving some time and effort.
The filename of your lexer should be the name of your programming language in
lower case followed by a *.lua* extension. For example, a new Lua lexer has
the name *lua.lua*.

Note: Try to refrain from using one-character language names like "c", "d",
or "r". For example, Scintillua uses "ansi_c", "dmd", and "rstats",
respectively.


<a id="lexer.New.Lexer.Template"></a>

### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a
new lexer. Feel free to use it, replacing the '?'s with the name of your
lexer:

    -- ? LPeg lexer.

    local l = require('lexer')
    local token, word_match = l.token, l.word_match
    local P, R, S = lpeg.P, lpeg.R, lpeg.S

    local M = {_NAME = '?'}

    -- Whitespace.
    local ws = token(l.WHITESPACE, l.space^1)

    M._rules = {
      {'whitespace', ws},
    }

    M._tokenstyles = {

    }

    return M

The first 3 lines of code simply define often used convenience variables. The
5th and last lines define and return the lexer object Scintilla uses; they
are very important and must be part of every lexer. The sixth line defines
something called a "token", an essential building block of lexers. You will
learn about tokens shortly. The rest of the code defines a set of grammar
rules and token styles. You will learn about those later. Note, however, the
`M.` prefix in front of `_rules` and `_tokenstyles`: not only do these tables
belong to their respective lexers, but any non-local variables need the `M.`
prefix too so-as not to affect Lua's global environment. All in all, this is
a minimal, working lexer that you can build on.


<a id="lexer.Tokens"></a>

### Tokens

Take a moment to think about your programming language's structure. What kind
of key elements does it have? In the template shown earlier, one predefined
element all languages have is whitespace. Your language probably also has
elements like comments, strings, and keywords. Lexers refer to these elements
as "tokens". Tokens are the fundamental "building blocks" of lexers. Lexers
break down source code into tokens for coloring, which results in the syntax
highlighting familiar to you. It is up to you how specific your lexer is when
it comes to tokens. Perhaps only distinguishing between keywords and
identifiers is necessary, or maybe recognizing constants and built-in
functions, methods, or libraries is desirable. The Lua lexer, for example,
defines 11 tokens: whitespace, comments, strings, numbers, keywords, built-in
functions, constants, built-in libraries, identifiers, labels, and operators.
Even though constants, built-in functions, and built-in libraries are subsets
of identifiers, Lua programmers find it helpful for the lexer to distinguish
between them all. It is perfectly acceptable to just recognize keywords and
identifiers.

In a lexer, tokens consist of a token name and an LPeg pattern that matches a
sequence of characters recognized as an instance of that token. Create tokens
using the [`lexer.token()`](#lexer.token) function. Let us examine the "whitespace" token
defined in the template shown earlier:

    local ws = token(l.WHITESPACE, l.space^1)

At first glance, the first argument does not appear to be a string name and
the second argument does not appear to be an LPeg pattern. Perhaps you
expected something like:

    local ws = token('whitespace', S('\t\v\f\n\r ')^1)

The `lexer` (`l`) module actually provides a convenient list of common token
names and common LPeg patterns for you to use. Token names include
[`lexer.DEFAULT`](#lexer.DEFAULT), [`lexer.WHITESPACE`](#lexer.WHITESPACE), [`lexer.COMMENT`](#lexer.COMMENT),
[`lexer.STRING`](#lexer.STRING), [`lexer.NUMBER`](#lexer.NUMBER), [`lexer.KEYWORD`](#lexer.KEYWORD),
[`lexer.IDENTIFIER`](#lexer.IDENTIFIER), [`lexer.OPERATOR`](#lexer.OPERATOR), [`lexer.ERROR`](#lexer.ERROR),
[`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR), [`lexer.CONSTANT`](#lexer.CONSTANT), [`lexer.VARIABLE`](#lexer.VARIABLE),
[`lexer.FUNCTION`](#lexer.FUNCTION), [`lexer.CLASS`](#lexer.CLASS), [`lexer.TYPE`](#lexer.TYPE), [`lexer.LABEL`](#lexer.LABEL),
[`lexer.REGEX`](#lexer.REGEX), and [`lexer.EMBEDDED`](#lexer.EMBEDDED). Patterns include
[`lexer.any`](#lexer.any), [`lexer.ascii`](#lexer.ascii), [`lexer.extend`](#lexer.extend), [`lexer.alpha`](#lexer.alpha),
[`lexer.digit`](#lexer.digit), [`lexer.alnum`](#lexer.alnum), [`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper),
[`lexer.xdigit`](#lexer.xdigit), [`lexer.cntrl`](#lexer.cntrl), [`lexer.graph`](#lexer.graph), [`lexer.print`](#lexer.print),
[`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space), [`lexer.newline`](#lexer.newline),
[`lexer.nonnewline`](#lexer.nonnewline), [`lexer.nonnewline_esc`](#lexer.nonnewline_esc), [`lexer.dec_num`](#lexer.dec_num),
[`lexer.hex_num`](#lexer.hex_num), [`lexer.oct_num`](#lexer.oct_num), [`lexer.integer`](#lexer.integer),
[`lexer.float`](#lexer.float), and [`lexer.word`](#lexer.word). You may use your own token names if
none of the above fit your language, but an advantage to using predefined
token names is that your lexer's tokens will inherit the universal syntax
highlighting color theme used by your text editor.


<a id="lexer.Example.Tokens"></a>

#### Example Tokens

So, how might you define other tokens like comments, strings, and keywords?
Here are some examples.

**Comments**

Line-style comments with a prefix character(s) are easy to express with LPeg:

    local shell_comment = token(l.COMMENT, '#' * l.nonnewline^0)
    local c_line_comment = token(l.COMMENT, '//' * l.nonnewline_esc^0)

The comments above start with a '#' or "//" and go to the end of the line.
The second comment recognizes the next line also as a comment if the current
line ends with a '\' escape character.

C-style "block" comments with a start and end delimiter are also easy to
express:

    local c_comment = token(l.COMMENT, '/*' * (l.any - '*/')^0 * P('*/')^-1)

This comment starts with a "/\*" sequence and contains anything up to and
including an ending "\*/" sequence. The ending "\*/" is optional so the lexer
can recognize unfinished comments as comments and highlight them properly.

**Strings**

It is tempting to think that a string is not much different from the block
comment shown above in that both have start and end delimiters:

    local dq_str = '"' * (l.any - '"')^0 * P('"')^-1
    local sq_str = "'" * (l.any - "'")^0 * P("'")^-1
    local simple_string = token(l.STRING, dq_str + sq_str)

However, most programming languages allow escape sequences in strings such
that a sequence like "\\&quot;" in a double-quoted string indicates that the
'&quot;' is not the end of the string. The above token incorrectly matches
such a string. Instead, use the [`lexer.delimited_range()`](#lexer.delimited_range) convenience
function.

    local dq_str = l.delimited_range('"')
    local sq_str = l.delimited_range("'")
    local string = token(l.STRING, dq_str + sq_str)

In this case, the lexer treats '\' as an escape character in a string
sequence.

**Keywords**

Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered
choices, use another convenience function: [`lexer.word_match()`](#lexer.word_match). It is
much easier and more efficient to write word matches like:

    local keyword = token(l.KEYWORD, l.word_match{
      'keyword_1', 'keyword_2', ..., 'keyword_n'
    })

    local case_insensitive_keyword = token(l.KEYWORD, l.word_match({
      'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
    }, nil, true))

    local hyphened_keyword = token(l.KEYWORD, l.word_match({
      'keyword-1', 'keyword-2', ..., 'keyword-n'
    }, '-'))

By default, characters considered to be in keywords are in the set of
alphanumeric characters and underscores. The last token demonstrates how to
allow '-' (hyphen) characters to be in keywords as well.

**Numbers**

Most programming languages have the same format for integer and float tokens,
so it might be as simple as using a couple of predefined LPeg patterns:

    local number = token(l.NUMBER, l.float + l.integer)

However, some languages allow postfix characters on integers.

    local integer = P('-')^-1 * (l.dec_num * S('lL')^-1)
    local number = token(l.NUMBER, l.float + l.hex_num + integer)

Your language may need other tweaks, but it is up to you how fine-grained you
want your highlighting to be. After all, you are not writing a compiler or
interpreter!


<a id="lexer.Rules"></a>

### Rules

Programming languages have grammars, which specify valid token structure. For
example, comments usually cannot appear within a string. Grammars consist of
rules, which are simply combinations of tokens. Recall from the lexer
template the `_rules` table, which defines all the rules used by the lexer
grammar:

    M._rules = {
      {'whitespace', ws},
    }

Each entry in a lexer's `_rules` table consists of a rule name and its
associated pattern. Rule names are completely arbitrary and serve only to
identify and distinguish between different rules. Rule order is important: if
text does not match the first rule, the lexer tries the second rule, and so
on. This simple grammar says to match whitespace tokens under a rule named
"whitespace".

To illustrate the importance of rule order, here is an example of a
simplified Lua grammar:

    M._rules = {
      {'whitespace', ws},
      {'keyword', keyword},
      {'identifier', identifier},
      {'string', string},
      {'comment', comment},
      {'number', number},
      {'label', label},
      {'operator', operator},
    }

Note how identifiers come after keywords. In Lua, as with most programming
languages, the characters allowed in keywords and identifiers are in the same
set (alphanumerics plus underscores). If the lexer specified the "identifier"
rule before the "keyword" rule, all keywords would match identifiers and thus
incorrectly highlight as identifiers instead of keywords. The same idea
applies to function, constant, etc. tokens that you may want to distinguish
between: their rules should come before identifiers.

So what about text that does not match any rules? For example in Lua, the '!'
character is meaningless outside a string or comment. Normally the lexer
skips over such text. If instead you want to highlight these "syntax errors",
add an additional end rule:

    M._rules = {
      {'whitespace', ws},
      {'error', token(l.ERROR, l.any)},
    }

This identifies and highlights any character not matched by an existing
rule as an `lexer.ERROR` token.

Even though the rules defined in the examples above contain a single token,
rules may consist of multiple tokens. For example, a rule for an HTML tag
could consist of a tag token followed by an arbitrary number of attribute
tokens, allowing the lexer to highlight all tokens separately. The rule might
look something like this:

    {'tag', tag_start * (ws * attributes)^0 * tag_end^-1}

Note however that lexers with complex rules like these are more prone to lose
track of their state.


<a id="lexer.Summary"></a>

### Summary

Lexers primarily consist of tokens and grammar rules. At your disposal are a
number of convenience patterns and functions for rapidly creating a lexer. If
you choose to use predefined token names for your tokens, you do not have to
define how the lexer highlights them. The tokens will inherit the default
syntax highlighting color theme your editor uses.


<a id="lexer.Advanced.Techniques"></a>

## Advanced Techniques


<a id="lexer.Styles.and.Styling"></a>

### Styles and Styling

The most basic form of syntax highlighting is assigning different colors to
different tokens. Instead of highlighting with just colors, Scintilla allows
for more rich highlighting, or "styling", with different fonts, font sizes,
font attributes, and foreground and background colors, just to name a few.
The unit of this rich highlighting is called a "style". Styles are simply
strings of comma-separated property settings. By default, lexers associate
predefined token names like `lexer.WHITESPACE`, `lexer.COMMENT`,
`lexer.STRING`, etc. with particular styles as part of a universal color
theme. These predefined styles include [`lexer.STYLE_CLASS`](#lexer.STYLE_CLASS),
[`lexer.STYLE_COMMENT`](#lexer.STYLE_COMMENT), [`lexer.STYLE_CONSTANT`](#lexer.STYLE_CONSTANT),
[`lexer.STYLE_ERROR`](#lexer.STYLE_ERROR), [`lexer.STYLE_EMBEDDED`](#lexer.STYLE_EMBEDDED),
[`lexer.STYLE_FUNCTION`](#lexer.STYLE_FUNCTION), [`lexer.STYLE_IDENTIFIER`](#lexer.STYLE_IDENTIFIER),
[`lexer.STYLE_KEYWORD`](#lexer.STYLE_KEYWORD), [`lexer.STYLE_LABEL`](#lexer.STYLE_LABEL), [`lexer.STYLE_NUMBER`](#lexer.STYLE_NUMBER),
[`lexer.STYLE_OPERATOR`](#lexer.STYLE_OPERATOR), [`lexer.STYLE_PREPROCESSOR`](#lexer.STYLE_PREPROCESSOR),
[`lexer.STYLE_REGEX`](#lexer.STYLE_REGEX), [`lexer.STYLE_STRING`](#lexer.STYLE_STRING), [`lexer.STYLE_TYPE`](#lexer.STYLE_TYPE),
[`lexer.STYLE_VARIABLE`](#lexer.STYLE_VARIABLE), and [`lexer.STYLE_WHITESPACE`](#lexer.STYLE_WHITESPACE). Like with
predefined token names and LPeg patterns, you may define your own styles. At
their core, styles are just strings, so you may create new ones and/or modify
existing ones. Each style consists of the following comma-separated settings:

Setting        | Description
---------------|------------
font:_name_    | The name of the font the style uses.
size:_int_     | The size of the font the style uses.
[not]bold      | Whether or not the font face is bold.
weight:_int_   | The weight or boldness of a font, between 1 and 999.
[not]italics   | Whether or not the font face is italic.
[not]underlined| Whether or not the font face is underlined.
fore:_color_   | The foreground color of the font face.
back:_color_   | The background color of the font face.
[not]eolfilled | Does the background color extend to the end of the line?
case:_char_    | The case of the font ('u': upper, 'l': lower, 'm': normal).
[not]visible   | Whether or not the text is visible.
[not]changeable| Whether the text is changeable or read-only.

Specify font colors in either "#RRGGBB" format, "0xBBGGRR" format, or the
decimal equivalent of the latter. As with token names, LPeg patterns, and
styles, there is a set of predefined color names, but they vary depending on
the current color theme in use. Therefore, it is generally not a good idea to
manually define colors within styles in your lexer since they might not fit
into a user's chosen color theme. Try to refrain from even using predefined
colors in a style because that color may be theme-specific. Instead, the best
practice is to either use predefined styles or derive new color-agnostic
styles from predefined ones. For example, Lua "longstring" tokens use the
existing `lexer.STYLE_STRING` style instead of defining a new one.


<a id="lexer.Example.Styles"></a>

#### Example Styles

Defining styles is pretty straightforward. An empty style that inherits the
default theme settings is simply an empty string:

    local style_nothing = ''

A similar style but with a bold font face looks like this:

    local style_bold = 'bold'

If you want the same style, but also with an italic font face, define the new
style in terms of the old one:

    local style_bold_italic = style_bold..',italics'

This allows you to derive new styles from predefined ones without having to
rewrite them. This operation leaves the old style unchanged. Thus if you
had a "static variable" token whose style you wanted to base off of
`lexer.STYLE_VARIABLE`, it would probably look like:

    local style_static_var = l.STYLE_VARIABLE..',italics'

The color theme files in the *lexers/themes/* folder give more examples of
style definitions.


<a id="lexer.Token.Styles"></a>

### Token Styles

Lexers use the `_tokenstyles` table to assign tokens to particular styles.
Recall the token definition and `_tokenstyles` table from the lexer template:

    local ws = token(l.WHITESPACE, l.space^1)

    ...

    M._tokenstyles = {

    }

Why is a style not assigned to the `lexer.WHITESPACE` token? As mentioned
earlier, lexers automatically associate tokens that use predefined token
names with a particular style. Only tokens with custom token names need
manual style associations. As an example, consider a custom whitespace token:

    local ws = token('custom_whitespace', l.space^1)

Assigning a style to this token looks like:

    M._tokenstyles = {
      custom_whitespace = l.STYLE_WHITESPACE
    }

Do not confuse token names with rule names. They are completely different
entities. In the example above, the lexer assigns the "custom_whitespace"
token the existing style for `WHITESPACE` tokens. If instead you want to
color the background of whitespace a shade of grey, it might look like:

    local custom_style = l.STYLE_WHITESPACE..',back:$(color.grey)'
    M._tokenstyles = {
      custom_whitespace = custom_style
    }

Notice that the lexer peforms Scintilla/SciTE-style "$()" property expansion.
You may also use "%()". Remember to refrain from assigning specific colors in
styles, but in this case, all user color themes probably define the
"color.grey" property.


<a id="lexer.Line.Lexers"></a>

### Line Lexers

By default, lexers match the arbitrary chunks of text passed to them by
Scintilla. These chunks may be a full document, only the visible part of a
document, or even just portions of lines. Some lexers need to match whole
lines. For example, a lexer for the output of a file "diff" needs to know if
the line started with a '+' or '-' and then style the entire line
accordingly. To indicate that your lexer matches by line, use the
`_LEXBYLINE` field:

    M._LEXBYLINE = true

Now the input text for the lexer is a single line at a time. Keep in mind
that line lexers do not have the ability to look ahead at subsequent lines.


<a id="lexer.Embedded.Lexers"></a>

### Embedded Lexers

Lexers embed within one another very easily, requiring minimal effort. In the
following sections, the lexer being embedded is called the "child" lexer and
the lexer a child is being embedded in is called the "parent". For example,
consider an HTML lexer and a CSS lexer. Either lexer stands alone for styling
their respective HTML and CSS files. However, CSS can be embedded inside
HTML. In this specific case, the CSS lexer is the "child" lexer with the HTML
lexer being the "parent". Now consider an HTML lexer and a PHP lexer. This
sounds a lot like the case with CSS, but there is a subtle difference: PHP
_embeds itself_ into HTML while CSS is _embedded in_ HTML. This fundamental
difference results in two types of embedded lexers: a parent lexer that
embeds other child lexers in it (like HTML embedding CSS), and a child lexer
that embeds itself within a parent lexer (like PHP embedding itself in HTML).


<a id="lexer.Parent.Lexer"></a>

#### Parent Lexer

Before embedding a child lexer into a parent lexer, the parent lexer needs to
load the child lexer. This is done with the [`lexer.load()`](#lexer.load) function. For
example, loading the CSS lexer within the HTML lexer looks like:

    local css = l.load('css')

The next part of the embedding process is telling the parent lexer when to
switch over to the child lexer and when to switch back. The lexer refers to
these indications as the "start rule" and "end rule", respectively, and are
just LPeg patterns. Continuing with the HTML/CSS example, the transition from
HTML to CSS is when the lexer encounters a "style" tag with a "type"
attribute whose value is "text/css":

    local css_tag = P('<style') * P(function(input, index)
      if input:find('^[^>]+type="text/css"', index) then
        return index
      end
    end)

This pattern looks for the beginning of a "style" tag and searches its
attribute list for the text "`type="text/css"`". (In this simplified example,
the Lua pattern does not consider whitespace between the '=' nor does it
consider that using single quotes is valid.) If there is a match, the
functional pattern returns a value instead of `nil`. In this case, the value
returned does not matter because we ultimately want to style the "style" tag
as an HTML tag, so the actual start rule looks like this:

    local css_start_rule = #css_tag * tag

Now that the parent knows when to switch to the child, it needs to know when
to switch back. In the case of HTML/CSS, the switch back occurs when the
lexer encounters an ending "style" tag, though the lexer should still style
the tag as an HTML tag:

    local css_end_rule = #P('</style>') * tag

Once the parent loads the child lexer and defines the child's start and end
rules, it embeds the child with the [`lexer.embed_lexer()`](#lexer.embed_lexer) function:

    l.embed_lexer(M, css, css_start_rule, css_end_rule)

The first parameter is the parent lexer object to embed the child in, which
in this case is `M`. The other three parameters are the child lexer object
loaded earlier followed by its start and end rules.


<a id="lexer.Child.Lexer"></a>

#### Child Lexer

The process for instructing a child lexer to embed itself into a parent is
very similar to embedding a child into a parent: first, load the parent lexer
into the child lexer with the [`lexer.load()`](#lexer.load) function and then create
start and end rules for the child lexer. However, in this case, swap the
lexer object arguments to [`lexer.embed_lexer()`](#lexer.embed_lexer). For example, in the PHP
lexer:

    local html = l.load('html')
    local php_start_rule = token('php_tag', '<?php ')
    local php_end_rule = token('php_tag', '?>')
    l.embed_lexer(html, M, php_start_rule, php_end_rule)


<a id="lexer.Lexers.with.Complex.State"></a>

### Lexers with Complex State

A vast majority of lexers are not stateful and can operate on any chunk of
text in a document. However, there may be rare cases where a lexer does need
to keep track of some sort of persistent state. Rather than using `lpeg.P`
function patterns that set state variables, it is recommended to make use of
Scintilla's built-in, per-line state integers via [`lexer.line_state`](#lexer.line_state). It
was designed to accommodate up to 32 bit flags for tracking state.
[`lexer.line_from_position()`](#lexer.line_from_position) will return the line for any position given
to an `lpeg.P` function pattern. (Any positions derived from that position
argument will also work.)

Writing stateful lexers is beyond the scope of this document.


<a id="lexer.Code.Folding"></a>

## Code Folding

When reading source code, it is occasionally helpful to temporarily hide
blocks of code like functions, classes, comments, etc. This is the concept of
"folding". In the Textadept and SciTE editors for example, little indicators
in the editor margins appear next to code that can be folded at places called
"fold points". When the user clicks an indicator, the editor hides the code
associated with the indicator until the user clicks the indicator again. The
lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences.
Examples of fold keywords are "if" and "end" in Lua and examples of fold
character sequences are '{', '}', "/\*", and "\*/" in C for code block and
comment delimiters, respectively. However, these fold points cannot occur
just anywhere. For example, lexers should not recognize fold keywords that
appear within strings or comments. The lexer's `_foldsymbols` table allows
you to conveniently define fold points with such granularity. For example,
consider C:

    M._foldsymbols = {
      [l.OPERATOR] = {['{'] = 1, ['}'] = -1},
      [l.COMMENT] = {['/*'] = 1, ['*/'] = -1},
      _patterns = {'[{}]', '/%*', '%*/'}
    }

The first assignment states that any '{' or '}' that the lexer recognized as
an `lexer.OPERATOR` token is a fold point. The integer `1` indicates the
match is a beginning fold point and `-1` indicates the match is an ending
fold point. Likewise, the second assignment states that any "/\*" or "\*/"
that the lexer recognizes as part of a `lexer.COMMENT` token is a fold point.
The lexer does not consider any occurences of these characters outside their
defined tokens (such as in a string) as fold points. Finally, every
`_foldsymbols` table must have a `_patterns` field that contains a list of
[Lua patterns][] that match fold points. If the lexer encounters text that
matches one of those patterns, the lexer looks up the matched text in its
token's table in order to determine whether or not the text is a fold point.
In the example above, the first Lua pattern matches any '{' or '}'
characters. When the lexer comes across one of those characters, it checks if
the match is an `lexer.OPERATOR` token. If so, the lexer identifies the match
as a fold point. The same idea applies for the other patterns. (The '%' is in
the other patterns because '\*' is a special character in Lua patterns that
needs escaping.) How do you specify fold keywords? Here is an example for
Lua:

    M._foldsymbols = {
      [l.KEYWORD] = {
        ['if'] = 1, ['do'] = 1, ['function'] = 1,
        ['end'] = -1, ['repeat'] = 1, ['until'] = -1
      },
      _patterns = {'%l+'}
    }

Any time the lexer encounters a lower case word, if that word is a
`lexer.KEYWORD` token and in the associated list of fold points, the lexer
identifies the word as a fold point.

If your lexer has case-insensitive keywords as fold points, simply add a
`_case_insensitive = true` option to the `_foldsymbols` table and specify
keywords in lower case.

If your lexer needs to do some additional processing to determine if a match
is a fold point, assign a function that returns an integer. Returning `1` or
`-1` indicates the match is a fold point. Returning `0` indicates it is not.
For example:

    local function fold_strange_token(text, pos, line, s, match)
      if ... then
        return 1 -- beginning fold point
      elseif ... then
        return -1 -- ending fold point
      end
      return 0
    end

    M._foldsymbols = {
      ['strange_token'] = {['|'] = fold_strange_token},
      _patterns = {'|'}
    }

Any time the lexer encounters a '|' that is a "strange_token", it calls the
`fold_strange_token` function to determine if '|' is a fold point. The lexer
calls these functions with the following arguments: the text to identify fold
points in, the beginning position of the current line in the text to fold,
the current line's text, the position in the current line the matched text
starts at, and the matched text itself.

[Lua patterns]: http://www.lua.org/manual/5.2/manual.html#6.4.1


<a id="lexer.Fold.by.Indentation"></a>

### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate
fold points. If your lexer falls into this category and you would like to
mark fold points based on changes in indentation, use the
`_FOLDBYINDENTATION` field:

    M._FOLDBYINDENTATION = true


<a id="lexer.Using.Lexers"></a>

## Using Lexers


<a id="lexer.Textadept"></a>

### Textadept

Put your lexer in your *~/.textadept/lexers/* directory so you do not
overwrite it when upgrading Textadept. Also, lexers in this directory
override default lexers. Thus, Textadept loads a user *lua* lexer instead of
the default *lua* lexer. This is convenient for tweaking a default lexer to
your liking. Then add a [file type][] for your lexer if necessary.

[file type]: _M.textadept.file_types.html


<a id="lexer.SciTE"></a>

### SciTE

Create a *.properties* file for your lexer and `import` it in either your
*SciTEUser.properties* or *SciTEGlobal.properties*. The contents of the
*.properties* file should contain:

    file.patterns.[lexer_name]=[file_patterns]
    lexer.$(file.patterns.[lexer_name])=[lexer_name]

where `[lexer_name]` is the name of your lexer (minus the *.lua* extension)
and `[file_patterns]` is a set of file extensions to use your lexer for.

Please note that Lua lexers ignore any styling information in *.properties*
files. Your theme file in the *lexers/themes/* directory contains styling
information.


<a id="lexer.Considerations"></a>

## Considerations


<a id="lexer.Performance"></a>

### Performance

There might be some slight overhead when initializing a lexer, but loading a
file from disk into Scintilla is usually more expensive. On modern computer
systems, I see no difference in speed between LPeg lexers and Scintilla's C++
ones. Optimize lexers for speed by re-arranging rules in the `_rules` table
so that the most common rules match first. Do keep in mind that order matters
for similar rules.


<a id="lexer.Limitations"></a>

### Limitations

Embedded preprocessor languages like PHP cannot completely embed in their
parent languages in that the parent's tokens do not support start and end
rules. This mostly goes unnoticed, but code like

    <div id="<?php echo $id; ?>">

or

    <div <?php if ($odd) { echo 'class="odd"'; } ?>>

will not style correctly.


<a id="lexer.Troubleshooting"></a>

### Troubleshooting

Errors in lexers can be tricky to debug. Lexers print Lua errors to
`io.stderr` and `_G.print()` statements to `io.stdout`. Running your editor
from a terminal is the easiest way to see errors as they occur.


<a id="lexer.Risks"></a>

### Risks

Poorly written lexers have the ability to crash Scintilla (and thus its
containing application), so unsaved data might be lost. However, I have only
observed these crashes in early lexer development, when syntax errors or
pattern errors are present. Once the lexer actually starts styling text
(either correctly or incorrectly, it does not matter), I have not observed
any crashes.


<a id="lexer.Acknowledgements"></a>

### Acknowledgements

Thanks to Peter Odding for his [lexer post][] on the Lua mailing list
that inspired me, and thanks to Roberto Ierusalimschy for LPeg.

[lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

## Fields defined by `lexer`

<a id="lexer.CLASS"></a>
### `lexer.CLASS` (string)

The token name for class tokens.

<a id="lexer.COMMENT"></a>
### `lexer.COMMENT` (string)

The token name for comment tokens.

<a id="lexer.CONSTANT"></a>
### `lexer.CONSTANT` (string)

The token name for constant tokens.

<a id="lexer.DEFAULT"></a>
### `lexer.DEFAULT` (string)

The token name for default tokens.

<a id="lexer.ERROR"></a>
### `lexer.ERROR` (string)

The token name for error tokens.

<a id="lexer.FOLD_BASE"></a>
### `lexer.FOLD_BASE` (number)

The initial (root) fold level.

<a id="lexer.FOLD_BLANK"></a>
### `lexer.FOLD_BLANK` (number)

Flag indicating that the line is blank.

<a id="lexer.FOLD_HEADER"></a>
### `lexer.FOLD_HEADER` (number)

Flag indicating the line is fold point.

<a id="lexer.FUNCTION"></a>
### `lexer.FUNCTION` (string)

The token name for function tokens.

<a id="lexer.IDENTIFIER"></a>
### `lexer.IDENTIFIER` (string)

The token name for identifier tokens.

<a id="lexer.KEYWORD"></a>
### `lexer.KEYWORD` (string)

The token name for keyword tokens.

<a id="lexer.LABEL"></a>
### `lexer.LABEL` (string)

The token name for label tokens.

<a id="lexer.LEXERPATH"></a>
### `lexer.LEXERPATH` (string)

The path used to search for a lexer to load.
  Identical in format to Lua's `package.path` string.
  The default value is `package.path`.

<a id="lexer.NUMBER"></a>
### `lexer.NUMBER` (string)

The token name for number tokens.

<a id="lexer.OPERATOR"></a>
### `lexer.OPERATOR` (string)

The token name for operator tokens.

<a id="lexer.PREPROCESSOR"></a>
### `lexer.PREPROCESSOR` (string)

The token name for preprocessor tokens.

<a id="lexer.REGEX"></a>
### `lexer.REGEX` (string)

The token name for regex tokens.

<a id="lexer.STRING"></a>
### `lexer.STRING` (string)

The token name for string tokens.

<a id="lexer.STYLE_BRACEBAD"></a>
### `lexer.STYLE_BRACEBAD` (string)

The style used for unmatched brace characters.

<a id="lexer.STYLE_BRACELIGHT"></a>
### `lexer.STYLE_BRACELIGHT` (string)

The style used for highlighted brace characters.

<a id="lexer.STYLE_CALLTIP"></a>
### `lexer.STYLE_CALLTIP` (string)

The style used by call tips if [`buffer.call_tip_use_style`](#buffer.call_tip_use_style) is set.
  Only the font name, size, and color attributes are used.

<a id="lexer.STYLE_CLASS"></a>
### `lexer.STYLE_CLASS` (string)

The style typically used for class definitions.

<a id="lexer.STYLE_COMMENT"></a>
### `lexer.STYLE_COMMENT` (string)

The style typically used for code comments.

<a id="lexer.STYLE_CONSTANT"></a>
### `lexer.STYLE_CONSTANT` (string)

The style typically used for constants.

<a id="lexer.STYLE_CONTROLCHAR"></a>
### `lexer.STYLE_CONTROLCHAR` (string)

The style used for control characters.
  Color attributes are ignored.

<a id="lexer.STYLE_DEFAULT"></a>
### `lexer.STYLE_DEFAULT` (string)

The style all styles are based off of.

<a id="lexer.STYLE_EMBEDDED"></a>
### `lexer.STYLE_EMBEDDED` (string)

The style typically used for embedded code.

<a id="lexer.STYLE_ERROR"></a>
### `lexer.STYLE_ERROR` (string)

The style typically used for erroneous syntax.

<a id="lexer.STYLE_FOLDDISPLAYTEXT"></a>
### `lexer.STYLE_FOLDDISPLAYTEXT` (string)

The style used for fold display text.

<a id="lexer.STYLE_FUNCTION"></a>
### `lexer.STYLE_FUNCTION` (string)

The style typically used for function definitions.

<a id="lexer.STYLE_IDENTIFIER"></a>
### `lexer.STYLE_IDENTIFIER` (string)

The style typically used for identifier words.

<a id="lexer.STYLE_INDENTGUIDE"></a>
### `lexer.STYLE_INDENTGUIDE` (string)

The style used for indentation guides.

<a id="lexer.STYLE_KEYWORD"></a>
### `lexer.STYLE_KEYWORD` (string)

The style typically used for language keywords.

<a id="lexer.STYLE_LABEL"></a>
### `lexer.STYLE_LABEL` (string)

The style typically used for labels.

<a id="lexer.STYLE_LINENUMBER"></a>
### `lexer.STYLE_LINENUMBER` (string)

The style used for all margins except fold margins.

<a id="lexer.STYLE_NUMBER"></a>
### `lexer.STYLE_NUMBER` (string)

The style typically used for numbers.

<a id="lexer.STYLE_OPERATOR"></a>
### `lexer.STYLE_OPERATOR` (string)

The style typically used for operators.

<a id="lexer.STYLE_PREPROCESSOR"></a>
### `lexer.STYLE_PREPROCESSOR` (string)

The style typically used for preprocessor statements.

<a id="lexer.STYLE_REGEX"></a>
### `lexer.STYLE_REGEX` (string)

The style typically used for regular expression strings.

<a id="lexer.STYLE_STRING"></a>
### `lexer.STYLE_STRING` (string)

The style typically used for strings.

<a id="lexer.STYLE_TYPE"></a>
### `lexer.STYLE_TYPE` (string)

The style typically used for static types.

<a id="lexer.STYLE_VARIABLE"></a>
### `lexer.STYLE_VARIABLE` (string)

The style typically used for variables.

<a id="lexer.STYLE_WHITESPACE"></a>
### `lexer.STYLE_WHITESPACE` (string)

The style typically used for whitespace.

<a id="lexer.TYPE"></a>
### `lexer.TYPE` (string)

The token name for type tokens.

<a id="lexer.VARIABLE"></a>
### `lexer.VARIABLE` (string)

The token name for variable tokens.

<a id="lexer.WHITESPACE"></a>
### `lexer.WHITESPACE` (string)

The token name for whitespace tokens.

<a id="lexer.alnum"></a>
### `lexer.alnum` (pattern)

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z',
    '0'-'9').

<a id="lexer.alpha"></a>
### `lexer.alpha` (pattern)

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
### `lexer.any` (pattern)

A pattern that matches any single character.

<a id="lexer.ascii"></a>
### `lexer.ascii` (pattern)

A pattern that matches any ASCII character (codes 0 to 127).

<a id="lexer.cntrl"></a>
### `lexer.cntrl` (pattern)

A pattern that matches any control character (ASCII codes 0 to 31).

<a id="lexer.dec_num"></a>
### `lexer.dec_num` (pattern)

A pattern that matches a decimal number.

<a id="lexer.digit"></a>
### `lexer.digit` (pattern)

A pattern that matches any digit ('0'-'9').

<a id="lexer.extend"></a>
### `lexer.extend` (pattern)

A pattern that matches any ASCII extended character (codes 0 to 255).

<a id="lexer.float"></a>
### `lexer.float` (pattern)

A pattern that matches a floating point number.

<a id="lexer.fold_level"></a>
### `lexer.fold_level` (table, Read-only)

Table of fold level bit-masks for line numbers starting from zero.
  Fold level masks are composed of an integer level combined with any of the
  following bits:

  * `lexer.FOLD_BASE`
    The initial fold level.
  * `lexer.FOLD_BLANK`
    The line is blank.
  * `lexer.FOLD_HEADER`
    The line is a header, or fold point.

<a id="lexer.graph"></a>
### `lexer.graph` (pattern)

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
### `lexer.hex_num` (pattern)

A pattern that matches a hexadecimal number.

<a id="lexer.indent_amount"></a>
### `lexer.indent_amount` (table, Read-only)

Table of indentation amounts in character columns, for line numbers
  starting from zero.

<a id="lexer.integer"></a>
### `lexer.integer` (pattern)

A pattern that matches either a decimal, hexadecimal, or octal number.

<a id="lexer.line_state"></a>
### `lexer.line_state` (table)

Table of integer line states for line numbers starting from zero.
  Line states can be used by lexers for keeping track of persistent states.

<a id="lexer.lower"></a>
### `lexer.lower` (pattern)

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.newline"></a>
### `lexer.newline` (pattern)

A pattern that matches any set of end of line characters.

<a id="lexer.nonnewline"></a>
### `lexer.nonnewline` (pattern)

A pattern that matches any single, non-newline character.

<a id="lexer.nonnewline_esc"></a>
### `lexer.nonnewline_esc` (pattern)

A pattern that matches any single, non-newline character or any set of end
  of line characters escaped with '\'.

<a id="lexer.oct_num"></a>
### `lexer.oct_num` (pattern)

A pattern that matches an octal number.

<a id="lexer.print"></a>
### `lexer.print` (pattern)

A pattern that matches any printable character (' ' to '~').

<a id="lexer.property"></a>
### `lexer.property` (table)

Map of key-value string pairs.

<a id="lexer.property_expanded"></a>
### `lexer.property_expanded` (table, Read-only)

Map of key-value string pairs with `$()` and `%()` variable replacement
  performed in values.

<a id="lexer.property_int"></a>
### `lexer.property_int` (table, Read-only)

Map of key-value pairs with values interpreted as numbers, or `0` if not
  found.

<a id="lexer.punct"></a>
### `lexer.punct` (pattern)

A pattern that matches any punctuation character ('!' to '/', ':' to '@',
  '[' to ''', '{' to '~').

<a id="lexer.space"></a>
### `lexer.space` (pattern)

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n',
  '\r', space).

<a id="lexer.style_at"></a>
### `lexer.style_at` (table, Read-only)

Table of style names at positions in the buffer starting from 1.

<a id="lexer.upper"></a>
### `lexer.upper` (pattern)

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
### `lexer.word` (pattern)

A pattern that matches a typical word. Words begin with a letter or
  underscore and consist of alphanumeric and underscore characters.

<a id="lexer.xdigit"></a>
### `lexer.xdigit` (pattern)

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').


## Functions defined by `lexer`

<a id="lexer.delimited_range"></a>
### `lexer.delimited_range` (chars, single\_line, no\_escape, balanced)

Creates and returns a pattern that matches a range of text bounded by
*chars* characters.
This is a convenience function for matching more complicated delimited ranges
like strings with escape characters and balanced parentheses. *single_line*
indicates whether or not the range must be on a single line, *no_escape*
indicates whether or not to ignore '\' as an escape character, and *balanced*
indicates whether or not to handle balanced ranges like parentheses and
requires *chars* to be composed of two characters.

Fields:

* `chars`: The character(s) that bound the matched range.
* `single_line`: Optional flag indicating whether or not the range must be
  on a single line.
* `no_escape`: Optional flag indicating whether or not the range end
  character may be escaped by a '\\' character.
* `balanced`: Optional flag indicating whether or not to match a balanced
  range, like the "%b" Lua pattern. This flag only applies if *chars*
  consists of two different characters (e.g. "()").

Usage:

* `local dq_str_escapes = l.delimited_range('"')`
* `local dq_str_noescapes = l.delimited_range('"', false, true)`
* `local unbalanced_parens = l.delimited_range('()')`
* `local balanced_parens = l.delimited_range('()', false, false, true)`

Return:

* pattern

See also:

* [`lexer.nested_pair`](#lexer.nested_pair)

<a id="lexer.embed_lexer"></a>
### `lexer.embed_lexer` (parent, child, start\_rule, end\_rule)

Embeds child lexer *child* in parent lexer *parent* using patterns
*start_rule* and *end_rule*, which signal the beginning and end of the
embedded lexer, respectively.

Fields:

* `parent`: The parent lexer.
* `child`: The child lexer.
* `start_rule`: The pattern that signals the beginning of the embedded
  lexer.
* `end_rule`: The pattern that signals the end of the embedded lexer.

Usage:

* `l.embed_lexer(M, css, css_start_rule, css_end_rule)`
* `l.embed_lexer(html, M, php_start_rule, php_end_rule)`
* `l.embed_lexer(html, ruby, ruby_start_rule, ruby_end_rule)`

<a id="lexer.fold"></a>
### `lexer.fold` (lexer, text, start\_pos, start\_line, start\_level)

Determines fold points in a chunk of text *text* with lexer *lexer*.
*text* starts at position *start_pos* on line number *start_line* with a
beginning fold level of *start_level* in the buffer. If *lexer* has a `_fold`
function or a `_foldsymbols` table, that field is used to perform folding.
Otherwise, if *lexer* has a `_FOLDBYINDENTATION` field set, or if a
`fold.by.indentation` property is set, folding by indentation is done.

Fields:

* `lexer`: The lexer object to fold with.
* `text`: The text in the buffer to fold.
* `start_pos`: The position in the buffer *text* starts at, starting at
  zero.
* `start_line`: The line number *text* starts on.
* `start_level`: The fold level *text* starts on.

Return:

* table of fold levels.

<a id="lexer.fold_line_comments"></a>
### `lexer.fold_line_comments` (prefix)

Returns a fold function (to be used within the lexer's `_foldsymbols` table)
that folds consecutive line comments that start with string *prefix*.

Fields:

* `prefix`: The prefix string defining a line comment.

Usage:

* `[l.COMMENT] = {['--'] = l.fold_line_comments('--')}`
* `[l.COMMENT] = {['//'] = l.fold_line_comments('//')}`

<a id="lexer.last_char_includes"></a>
### `lexer.last_char_includes` (s)

Creates and returns a pattern that verifies that string set *s* contains the
first non-whitespace character behind the current match position.

Fields:

* `s`: String character set like one passed to `lpeg.S()`.

Usage:

* `local regex = l.last_char_includes('+-*!%^&|=,([{') *
  l.delimited_range('/')`

Return:

* pattern

<a id="lexer.lex"></a>
### `lexer.lex` (lexer, text, init\_style)

Lexes a chunk of text *text* (that has an initial style number of
*init_style*) with lexer *lexer*.
If *lexer* has a `_LEXBYLINE` flag set, the text is lexed one line at a time.
Otherwise the text is lexed as a whole.

Fields:

* `lexer`: The lexer object to lex with.
* `text`: The text in the buffer to lex.
* `init_style`: The current style. Multiple-language lexers use this to
  determine which language to start lexing in.

Return:

* table of token names and positions.

<a id="lexer.line_from_position"></a>
### `lexer.line_from_position` (pos)

Returns the line number of the line that contains position *pos*, which
starts from 1.

Fields:

* `pos`: The position to get the line number of.

Return:

* number

<a id="lexer.load"></a>
### `lexer.load` (name, alt\_name, cache)

Initializes or loads and returns the lexer of string name *name*.
Scintilla calls this function in order to load a lexer. Parent lexers also
call this function in order to load child lexers and vice-versa. The user
calls this function in order to load a lexer when using Scintillua as a Lua
library.

Fields:

* `name`: The name of the lexing language.
* `alt_name`: The alternate name of the lexing language. This is useful for
  embedding the same child lexer with multiple sets of start and end tokens.
* `cache`: Flag indicating whether or not to load lexers from the cache.
  This should only be `true` when initially loading a lexer (e.g. not from
  within another lexer for embedding purposes).
  The default value is `false`.

Return:

* lexer object

<a id="lexer.nested_pair"></a>
### `lexer.nested_pair` (start\_chars, end\_chars)

Returns a pattern that matches a balanced range of text that starts with
string *start_chars* and ends with string *end_chars*.
With single-character delimiters, this function is identical to
`delimited_range(start_chars..end_chars, false, true, true)`.

Fields:

* `start_chars`: The string starting a nested sequence.
* `end_chars`: The string ending a nested sequence.

Usage:

* `local nested_comment = l.nested_pair('/*', '*/')`

Return:

* pattern

See also:

* [`lexer.delimited_range`](#lexer.delimited_range)

<a id="lexer.starts_line"></a>
### `lexer.starts_line` (patt)

Creates and returns a pattern that matches pattern *patt* only at the
beginning of a line.

Fields:

* `patt`: The LPeg pattern to match on the beginning of a line.

Usage:

* `local preproc = token(l.PREPROCESSOR, l.starts_line('#') *
  l.nonnewline^0)`

Return:

* pattern

<a id="lexer.token"></a>
### `lexer.token` (name, patt)

Creates and returns a token pattern with token name *name* and pattern
*patt*.
If *name* is not a predefined token name, its style must be defined in the
lexer's `_tokenstyles` table.

Fields:

* `name`: The name of token. If this name is not a predefined token name,
  then a style needs to be assiciated with it in the lexer's `_tokenstyles`
  table.
* `patt`: The LPeg pattern associated with the token.

Usage:

* `local ws = token(l.WHITESPACE, l.space^1)`
* `local annotation = token('annotation', '@' * l.word)`

Return:

* pattern

<a id="lexer.word_match"></a>
### `lexer.word_match` (words, word\_chars, case\_insensitive)

Creates and returns a pattern that matches any single word in list *words*.
Words consist of alphanumeric and underscore characters, as well as the
characters in string set *word_chars*. *case_insensitive* indicates whether
or not to ignore case when matching words.
This is a convenience function for simplifying a set of ordered choice word
patterns.

Fields:

* `words`: A table of words.
* `word_chars`: Optional string of additional characters considered to be
  part of a word. By default, word characters are alphanumerics and
  underscores ("%w_" in Lua). This parameter may be `nil` or the empty string
  in order to indicate no additional word characters.
* `case_insensitive`: Optional boolean flag indicating whether or not the
  word match is case-insensitive. The default is `false`.

Usage:

* `local keyword = token(l.KEYWORD, word_match{'foo', 'bar', 'baz'})`
* `local keyword = token(l.KEYWORD, word_match({'foo-bar', 'foo-baz',
  'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, '-', true))`

Return:

* pattern


## Tables defined by `lexer`

<a id="lexer.lexer"></a>
### `lexer.lexer`

Individual fields for a lexer instance.

Fields:

* `_NAME`: The string name of the lexer.
* `_rules`: An ordered list of rules for a lexer grammar.
  Each rule is a table containing an arbitrary rule name and the LPeg pattern
  associated with the rule. The order of rules is important, as rules are
  matched sequentially.
  Child lexers should not use this table to access and/or modify their
  parent's rules and vice-versa. Use the `_RULES` table instead.
* `_tokenstyles`: A map of non-predefined token names to styles.
  Remember to use token names, not rule names. It is recommended to use
  predefined styles or color-agnostic styles derived from predefined styles
  to ensure compatibility with user color themes.
* `_foldsymbols`: A table of recognized fold points for the lexer.
  Keys are token names with table values defining fold points. Those table
  values have string keys of keywords or characters that indicate a fold
  point whose values are integers. A value of `1` indicates a beginning fold
  point and a value of `-1` indicates an ending fold point. Values can also
  be functions that return `1`, `-1`, or `0` (indicating no fold point) for
  keys which need additional processing.
  There is also a required `_patterns` key whose value is a table containing
  Lua pattern strings that match all fold points (the string keys contained
  in token name table values). When the lexer encounters text that matches
  one of those patterns, the matched text is looked up in its token's table
  to determine whether or not it is a fold point.
  There is also an optional `_case_insensitive` option that indicates whether
  or not fold point keys are case-insensitive. If `true`, fold point keys
  should be in lower case.
* `_fold`: If this function exists in the lexer, it is called for folding
  the document instead of using `_foldsymbols` or indentation.
* `_lexer`: The parent lexer object whose rules should be used. This field
  is only necessary to disambiguate a proxy lexer that loaded parent and
  child lexers for embedding and ended up having multiple parents loaded.
* `_RULES`: A map of rule name keys with their associated LPeg pattern
  values for the lexer.
  This is constructed from the lexer's `_rules` table and accessible to other
  lexers for embedded lexer applications like modifying parent or child
  rules.
* `_LEXBYLINE`: Indicates the lexer can only process one whole line of text
   (instead of an arbitrary chunk of text) at a time.
   The default value is `false`. Line lexers cannot look ahead to subsequent
   lines.
* `_FOLDBYINDENTATION`: Declares the lexer does not define fold points and
   that fold points should be calculated based on changes in indentation.

- - -

