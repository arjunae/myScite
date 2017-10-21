:: Publish-Module for Node.js (currently win only)
:: (c) Valentin Schmidt 2016

Publish module for creating standalone desktop applications based on Node.js.
It's run by pressing the "Publish for Win"-button (or F8) in the "Projects"
tab of the SciTE sidebar when a project of type "node" that contains a
[PublishWin] section is loaded.

Before using it, change the %NODE_MOD_DIR% config variable at the top of script
"make_win.bat", so it points to an actual local folder from which all specified 
node-modules should be copied.

Check the comments in demo project file "fxSvgViewer-node.project" (INI format)
to understand how configuration works. Publishing this demo project requires 
"node-qt":

  http://valentin.dasdeck.com/js/node_qt/win/node-qt_win.zip

to be installed in %NODE_MOD_DIR%.

A published standalone version of the demo can be found at:
http://valentin.dasdeck.com/projects/scite_sidebar/published_projects/

The publish module currently uses a copy of node.exe v0.8.25 as "runtime" for the 
published standalone applications. It's the official version, but with a few bytes
changed in the PE header to remove the console window. If you want to use
another version of node.exe, you can use the included perl script "exetype.pl"
to prepare it the same way.

  Usage: perl exetype.pl node.exe WINDOWS