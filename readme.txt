~# mySciTE -~

[28.11.2019] mySciTE.190.xx MartyMcFly (Lua5.1 & Lua5.3)
  =Maintenance Update=
lua: allow using lua "stdlib" extensions within "addons/lua" folder
lua: make interpreter callable via os shell "mylua.bat"
lua: update libs to current versions
lua: add inspect/ luasec (https support) / bk_trees
lua: refactor files for SciteDebug / fix debuggerPrompt on sessionEnd
lua: Add experimental OnPaneInsert/OnPaneAppend Events
lexlpeg: add batch keywords
lexmake: fix stray whitespace issues, singleQuotes in UserVars
src: Unify sources and dependencies where appropiate within myscite 190.x
themes: finish rebalancing colours for better contrast. 

[22.01.2019] mySciTE.190.02 MartyMcFly (Lua5.1 & Lua5.3)
  =Maintenance Release=
# Upd: scintilla: Update c based lexers to those in current scintilla (4.1.3)
# Upd: lexer: batchfiles are lexed by a luaLpeg based lexer now.
# Fix: Build System: enable compiling on Linux and VC again.
# Upd: properties: redone php (7.2) and c api files. 
# Add: tools: added a simple update checker.
# Upd: userlists can be styled with style calltip (38).
# Upd: Themeing: Major CleanUp.
-> (30.03.2019) LexMake: CleanUp Code / Fix a rarely occuring assertion.

[13.07.2018] myScite.190.01MartyMcFly (Lua5.1 & Lua5.3)
  =Maintenance Release=
# Fix: Fixes for Language Support and Themeing.
# Upd: Enhanced LexMake (support qMake &  EolWarns on Multiline Continuations).
# Upd: Tuned lua Script load order.
# Add: Added Installer (Win32/Win64)
# Upd: Based on Foicica's Scintilla (3.8.0) cpp11 backport and SciTE Mainline (3.7.5).
-> (18.03.2019) Fix a rarely occuring assertion in LexMake.
 
[12.01.2018] myScite.190.MartyMcFly (Lua5.1 & Lua5.3)
# Add: SciTE Project Support. Settings for scite sources included.
# Add: cTags Navigation support within project source files. ( ALT-Click )
# Add: cTags based, cached Projects and Platform SDK sourceCode Highlightening. 
# Upd: cTags and Artistic Style. /Upd: Autocomplete and theme.solarized.
# Upd: c89,90,95,03,11 docs from en.wikibooks.org for Syntax Highlightening *kudos*.
# New: Properties max.style.size and window.flatui.
# New: Highlight Current Word Counter in Status Bar.
# Fix: StartUp Performance heavily improved.
# Info: Dual Release. Lua5.1.5 and Lua5.3.4 available.  
# Contains Scintillua, Hunspell, Exuberant cTags and aStyle.

[25.11.2017] myScite.180.Artie.stable
# Add: Lisp / Scheme / Clojure / GO Language Keywords
# Fix: lexMakeEOF & Add Folding / Fix: remove MSVC10 dependency
# Fix: lua: more flexibility while loading hunspell.dll
# Add: lua: luasocket, mime, http, sha2, underscore & serpent. Add Tests
# New: lua: Events OnClick (singleClick) && OnInit (called once on Scite Startup) 
# New: lua: AutoComplete any enabled by default.
# New: lexer: Highlight eMail Links && Highlight GUIDs / Increase FindMarks Speed. 
# New: Theme: Adapted theme solarized
# New: CRC Verify SciLexer.dll during Start. 
# Upd: Based on scintilla-scite 3.7.5 now. (was 3.7.0)

[22.09.2017] myScite.160.Augustine.stable
# API: Actionscript3, FreeBasic, ArduinoC. Ordered cpp by header.
# Theming: TonedDown Colors to be more EyeFriendly and readable.
# Lexer: enhanced Makefile Lexer Features. (keywords and styles) 
# Lexer: Added scintillua antlr lexer. 
# luaLibs: moved shell.dll->ibox to gui.dll. (Now more efficient and 50% smaller.)
# others: more Fun for lua Testcases :) 

[29.06.2017] mySciTE.153.June.stable
# antialiased fonts. Style .json & .mib Files. / Add Forth and Fortran api.
# lua repo: unified mingw makefiles. / Recompiled all libs with Os for a better opt balance.
# included luasocket (ip socket support) 
# included luacom (win com objects. eg speech / mshtml and others)
# reworked env.home & env.userhome (handle readonly places / use profiles)
# reworked c/cpp syntax colouring for iso c99/cpp98/cpp11 + apiFiles.
# style nonstandart and unsafe c functions. / Added w32 types.
# more userfriendly appendContextMenu script / Extman Update
# improved makefile Lexer. (Styles Flags, internal vars & functions, User Vars)
# removed pthreads dll Dependency. Add Keyword Index to lua5.1 chm Help.
# many BugFixes / We finally, Linux 32 and 64bit binaries made their way here :)

[13.04.2017] STABLE-1.50 
# Rebased from wScite 3.6.7 to 3.7.0
# Update lPeg from .10 to .12
# Fix scites variable Expansion for "Import" Statement 
# Add Powershell / Matlab / VHDL / Markdown / Rust / r props.
 # Support simple Markdown for plainText files.
# Enhance Installer Script / Redone theme.coffee / theme.grey
 # Cleaned Build System / Moved SciTE-Lua-Libs to an own Repo. 
# Scintillua for win64 & linux ports.
# changes to lua subsystem.

[08.Dezember.2016] STABLE-136
# addons: Add Scite Ctags (credits mingfunwong)
 # Path-sandbox for tools. / small fixes to Addons. (orthospell & Sidebar)
# editor: fix nonequal line height / Styles for DocComments. 
# other: faster runtime compression for libs 
# profiles with env.scite_home / $(env.home)

[11.November.2016] STABLE-130
# api: Add coffeescript abd CSS3 Keywords | fix jQuery and vbs Calltips
# editor: 3Tone Styles | optimized Fonts. (Zoom with alt-pgup/pgdown)
# Addons: Add mod-scintilulla (15 new lexers) | Add mod-orthospell | smaller libs 
# common: Sync linux properties | add Documentation | include winpthreads
# others: Fix Installer (reactOS) | cleanup SourceTree | default theme white.
# 8) MINI-Little-and-Sweet Package. Full Package see (github/arjunae)
 
[04.November.2016] DEVEL-124
# @arjunae cleanup js/jq keywords add Dom Exceptions / add lua.scite.api	
# @arjunae Additional HTML5 Keywords (final W3C 28.Okt.14) 
# @arjunae Move all Language related files to user/languages
# @arjunae Update HelpFiles / Fix Installer # register scite in [open With -programName-] List
# @arjunae Add errlist output-pane # makefile # hexedit & debug styles .
#  themeblackBlue: add 3 tones Styling
# @arjunae Calltips: Allow to distinguish btw properties and functions.

[29.10.2016] STABLE-1.23
# api:  fix: styling html/vbs/ruby/perl | New: java1.8 & freebasic Keywords 
# themes: sync theme grey and theme blackblue
# compatibility: fix: styles aliases for other scite forks
# steampunk: fix: filetype register batchfiles
# addons: fix: hexEdit / change some testcases
# 8) MINI-Little-and-Sweet Package. Full Package see (github/arjunae)

[25.10.2016] STABLE-1.22
# editor: default to unicode / scaling for window and margins
# apis:   add BrowserWebApi / improve php and vbs api / fix linebreaks
# props: clike: add AS3 Keywords / updates to js1.6
# tools: simplified samples / fixed figref / add lua mod-mitchel
# themes: better styles & monospace font / Zooming (Alt+Pgup/PgDown)

[21.10.2016] STABLE-1.21
# sync with scintilla-scite 3.67
# Fixes for styling cpp macros, html tags and wsh objects
# Finalize theme.grey
# Fix lua debugging
# Fix Addon System
# Full Version available on github.

[24.08.2016] [DEV-1.13]
# New Feature: Window transparency. 
#  propertyName in percent of opaque: int window.transparency=96
# change: further improved theme contrast
# add: XML keywords for vbs 
# fix: cpp api fetcher

[19.08.2016] [Stable-1.12]
# Fixes for cpp/html/batch/vbscript styling.
# Formatting Cleanups for Calltips in javascript and jQuery.api (Linebreaks).
# More eyeFriendly theme.blackblue and theme.coffee
# Higher contrast and monospace Font within the output pane. 

[16.08.2016] [Stable-1.11]
# Redone; Portability Patch.
# Use %userprofile%\.Scite, $(env.scite_userhome) or just Scite's binPath.    
# Fix; MSDN and CPP API File parsers.
# New; Properties: Include XML & Yaml. Most props use theming / New theme.white
# Redone VBA/WSH/JS APis.
# New; Autocomplete: Grow and Shrink List dynamically.
# Fix; Calltips: Now finally helpful and usable.
# New; Use "release" Bins by default to reduce download size.
# Fix; Remove unnecessary runtime dependencies. Be friendly to Reactos RC1.
# New; .add_toolPath.cmd to Set Path for Scites Toolbase.
# Change; Move all Lua related files to Addons\lua-modules
# Change; Add wrapper scripts for all Tools and move them to Addons\tools
# Add; Code Linter (with gcc) and Beautify Tools (Uncrustify)
