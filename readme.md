~- mySciTE.webdev -~

[04.November.2016] (https://github.com/arjunae/myScite/releases) DEVEL-124
- @arjunae cleanup js/jq keywords add Dom Exceptions / add lua.scite.api	
- @arjunae Additional HTML5 Keywords (final W3C 28.Okt.14) 
- @arjunae Move all Language related files to user/languages
- @arjunae Update HelpFiles / Fix Installer - register scite in [open With -programName-] List
- @arjunae Add errlist output-pane - makefile - hexedit & debug styles .
-  themeblackBlue: add 3 tones Styling
- @arjunae Calltips: Allow to distinguish btw properties and functions.
	
[21.10.2016](https://github.com/arjunae/myScite/releases) STABLE-1.21
- sync with scintilla-scite 3.67
- Fixes for styling cpp macros, html tags and wsh objects
- Finalize theme.grey
- Fix lua debugging
- Fix Addon System
- Full Version available on github.

[24.08.2016] [DEV-1.13]
- New Feature: Window transparency. 
-  propertyName in percent of opaque: int window.transparency=96
- change: further improved theme contrast
- add: XML keywords for vbs 
- fix: cpp api fetcher

[19.08.2016] [Stable-1.12]
- Fixes for cpp/html/batch/vbscript styling.
- Formatting Cleanups for Calltips in javascript and jQuery.api (Linebreaks).
- More eyeFriendly theme.blackblue and theme.coffee
- Higher contrast and monospace Font within the output pane. 

[16.08.2016] [Stable-1.11]
-- Redone; Portability Patch.
- Use %userprofile%\.Scite, $(env.scite_userhome) or just Scite's binPath.    
- Fix; MSDN and CPP API File parsers.
- New; Properties: Include XML & Yaml. Most props use theming / New theme.white
- Redone VBA/WSH/JS APis.
- New; Autocomplete: Grow and Shrink List dynamically.
- Fix; Calltips: Now finally helpful and usable.
- New; Use "release" Bins by default to reduce download size.
- Fix; Remove unnecessary runtime dependencies. Be friendly to Reactos RC1.
- New; .add_toolPath.cmd to Set Path for Scites Toolbase.
- Change; Move all Lua related files to Addons\lua-modules
- Change; Add wrapper scripts for all Tools and move them to Addons\tools
- Add; Code Linter (with gcc) and Beautify Tools (Uncrustify)
