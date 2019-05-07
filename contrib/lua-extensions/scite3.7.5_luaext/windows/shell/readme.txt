=shell.dll=

Author: mozers

Original Post:
https://groups.google.com/forum/#!searchin/scite-interest/getfileattr$20%7Csort:date/scite-interest/bVeyCfZ3OIc/J8Vg0uI9IcUJ

==========

I present the new Lua library for SciTE created by Ru-Board team.

It includes the following functions:
* msgbox - Showing text message with buttons.
* getfileattr & setfileattr - Get and set file attributes
* fileexists - Check exist file or folder with specified name
* exec - Run external programm or open file with associate application. Allows to execute files, documents and links and to open folders in Windows Explorer.
* findfiles - Searches for files and folders with mask and returned result as the table.

Documentation: http://scite-ru.googlecode.com/svn/trunk/pack/tools/LuaLib/shell.html
SHELL.DLL: http://scite-ru.googlecode.com/svn/trunk/pack/tools/LuaLib/shell.dll
Source code: http://scite-ru.googlecode.com/svn/trunk/shell/

Successfully we use it long ago, but the English documentation established recently.

Special thanks to Steve Donovan for an initial variant exec-function.
--
mozers
<http://code.google.com/p/scite-ru/>
