:: Publish-Module for Lua (currently win only)
:: (c) Valentin Schmidt 2016

Publish module for creating standalone desktop applications based on Lua.
It's run by pressing the "Publish for Win"-button (or F8) in the "Projects"
tab of the SciTE sidebar when a project of type "lua" that contains a
[PublishWin] section is loaded.

Before using it, change the %LUA_DIR% config variable at the top of script
"make_win.bat", so it points to your actual local Lua directory.

Check the comments in demo project file "fxSvgViewer-lua.project" (INI format)
to understand how configuration works. Publishing this demo project requires
"lqt":

    https://github.com/downloads/mkottman/lqt/lqt_0.9_win_qt4.7.4.zip
    
to be installed in your local Lua folder, with the Dlls of <ZIP>\lua copied to
%LUA_DIR%\clibs, and the DLLs of <ZIP>\qt copied to %LUA_DIR% (i.e. your Lua 
root folder).

A published standalone version of the demo can be found at:
http://valentin.dasdeck.com/projects/scite_sidebar/published_projects/
