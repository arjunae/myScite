~- SciTE_webdev -~

[17.08.2016]
- Removed Screenshots from older Revisions.
- Formatting Cleanups for Calltips in javascript.api (Linebreaks).
- Higher contrast and monospace Font within the output pane. 


[16.08.2016]	::.:::..:: Stable Release (1.11) ::.:::..::

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
