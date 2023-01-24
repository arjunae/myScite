# scite-gui

Author: Steve Donovan ~2008

Modifications:
- copied lfs.dir to gui.dir. (takes path, returns fileAttrib, fileName) 
- gui.files still available. (Also fixed a handle Leak in there.) 
- shell.inputbox was moved to gui.inputbox. 

Notes:
- works (still) fine with SciteLua 5.1 win32
- problems: splitter (only mingw-w64) and ext.lua.auto.reload (SciteLua5.3)

Original Post:
https://groups.google.com/forum/#!searchin/scite-interest/gui.dll%7Csort:date/scite-interest/yZubpejP-bM/Ig4llcQLBgAJ