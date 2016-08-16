@ECHO OFF
SET PATH=H:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

mingw32-make all
if errorlevel 1 goto eof
move /y *.dll ..\_clib_bin 

mingw32-make clean
:eof
