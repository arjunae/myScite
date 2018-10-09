Orthospell for SciTE                                  version 1.1, October 2014
--------------------

Download site: http://tools.diorama.ch

Orthospell is based on luahunspell by Matt White
Website: https://code.google.com/p/luahunspell/

Advanced features of Orthospell:

  - support of languages with special characters such as umlauts
  - support of UTF-8 (documents  and dictionaries)
    up to U+053F (Cyrillic) for documents
  - selection of alternative dictionaries from the SciTE Tools menu
  - integration of a custom user dictionary (new in version 1.1)
  - full support of HTML files
        - no checking of tags and their attributes
        - no checking of style and script sections
        - no checking of HTML entities
        - support of soft hyphens (&shy;)
  - support of markdown files
  - support of LaTeX files (may need improvement)
  - support of other (markup-) languages can be added, see the notes inside the
    script

    NOTE: Orthospell assumes hat all hunspell dictionaries, except French, use an
          ISO code page. If your dictionary uses a different one, you must change
          the setting inside the script's language section.

!! This script works in windows only (for Linux changes are necessary).

How to install
--------------
- Download all necessary files bundled from tools.diorama.ch

or

1. Download orthospell.lua and extman.lua from tools.diorama.ch
2. Download hunspell.dll (https://code.google.com/p/luahunspell/downloads/list)
3. Download shell.dll from
   http://scite-ru.googlecode.com/hg/pack/tools/LuaLib/shell.dll

- The dll libraries must be placed into the SciTE root directory
- orthospell.lua must be placed into the scite_lua directory
- extman.lua must be placed into the SciTE root directory

The following line must be written into the SciTEUser.properties file

     ext.lua.startup.script=$(SciteDefaultHome)\extman.lua

The following parameters are used for customizing (SciTEUser.properties)
  - spell.dictpath=$(SciteDefaultHome)\<directory> default: SciTE root directory
  - spell.dictname=<hunspell dict names> default: en_US; see below multilanguage
  - spell.userdict=<user dictionary file>
  - file.patterns.spell=<file extensions> default: all; files for which the spell
    functions are shown in the Tools menu

How to use
----------

Invoke spell checking by either selecting it from the Tools menu or pressing F9.
Misspelled or unknown words are highlighted by a red underline. Get spell
suggestions by double-clicking on the highlighted word.

Important note for existing users of luahunspell
------------------------------------------------
You must remove 'spellcheck.lua' from the 'scite_lua' directory! Apart from
downloading the shell.dll, no other changes are required. The
'file.patterns.spell' property, however, works only with the extman.lua version
that comes with Orthospell.

Multilanguage support
---------------------
Simply add all the dictionary names you want to use - separated by | - to the
spell.dictname parameter in your User or Global options file

e.g. spell.dictname=en_US|fr-classique|de_DE|en-GB

Make sure you spell the names correctly (some use a hyphen, others an underline)

Customization
-------------

The script has a highly modular design which makes it easy to extend it's
functionality to other natural and programming languages (see the notes inside
the script)

