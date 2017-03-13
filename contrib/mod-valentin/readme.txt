-- Sidebar for SciTE v0.3 (Lua version)
-- (c) Valentin Schmidt 2016
-- License: WTFPL 2.0


This is a port of my Sidebar for SciTE (originally written in Lingo) to Lua.

Notice: SFTP support not available yet in this version - this requires to
re-compile the cURL Lua extension with SFTP support. It's on my To-Do list, 
but means work...

Requirements
============

The SciTE sidebar uses the Lua extension "winapi", which depends on the MS
Visual Studio C Runtime DLL "msvcr100.dll" (x86). If you see an error message
when starting SciTE, this means that this DLL is missing in your system, in this
case you first have to install vcredist_msvc2010_x86.exe.

Features
========

    Note:
    All key shortcuts listed below are just the defaults, they can be adjusted
    to your personal preferences.

The Sidebar is implemented in Lua and Qt, and uses a Lua script as backend
which is loaded via "Scite Ext Man" (extman.lua).

The Sidebar (if autostart is deactivated, see below) can be started by typing
Ctrl+E, and any subsequent Ctrl+E toggles its visibility.

By default the Sidebar is started automatically with SciTE. You can change this
behavior by setting sidebar.autostart=0 in the SciTE config file
"SciTEGlobal.properties".

By default the Sidebar is presented as fixed panel without title bar on the
right side of the SciTE window. Its position is updated automatically when the
SciTE window's position/size was changed.

Alternatively - by changing "position=fixed" to "position=floating" in Sidebar's
main configuration file "sidebar.ini" - you can use it as "floating panel" with
title bar that you can move to your preferred location via mouse.

The Sidebar currently has the following 5 features/tabs (unwanted tabs can be
deactivated by editing the "[Tabs]" section in "sidebar.ini"):


Tab "Explorer" (Alt+Shift+E)
============================

A file explorer that shows all drives under "My Computer" and opens
double-clicked files in SciTE.

By default the Explorer shows all drives under "My Computer". You can change
this behavior by editing the "root" parameter in the Explorer's config file
"explorer.ini". You can  change its "root" e.g. to a specific drive (root=D:/),
a specific folder (root=D:/foo/bar) or a network volume
(root=//192.168.2.23/).


Tab "FTP" (Alt+Shift+T)
============================

Allows to open files (via double-click) from FTP/SFTP accounts directly in
SciTE, and saving changes automatically re-uploads the changed file to the 
corresponding server.


Tab "Functions" (Alt+Shift+F)
=============================

Shows list of functions in the current activated buffer, and when a function
name is double-clicked, jumps to the corresponding line in the code. Currently
supported languages: C/C++, INI, JS, Lingo/LSW, PHP (extensible).


Tab "Favs" (Alt+Shift+B)
========================

Allows to specify bookmarks ("favs") for quick access, both of files (which
are then opened in SciTE) and folders (which are opened in Sidebar's file
explorer, see above).


Tab "Projects" (Alt+Shift+P)
============================

Simple project management based on *.project files in INI-format. Project INI
files can be dragged into the "Projects" tab, and you can specify your current 
project as default in Sidebar's main configuration file "sidebar.ini", which is 
then loaded automatically on start.

The "Projects" Tab also has buttons that allow to "publish" projects as
standalone (desktop) applications, which is meant for creating distributable
applications based on interpreters as runtime, by copying everything needed into
a single folder (which can optionally also be zipped automatically). There are
currently 2 "publish modules", one for Lua and one for Node.js (both currently
win-only). Check out the readme.txt files in folders:
- sidebar\publish\modules\lua\
- sidebar\publish\modules\node\
as well the readme.txt files in the 2 demo project folders:
- sidebar\projects\fxSvgViewer-lua\
- sidebar\projects\fxSvgViewer-node\
for details.