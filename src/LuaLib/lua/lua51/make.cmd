@ECHO OFF

mingw32-make clean

mingw32-make
if errorlevel 1 goto eof

move *.dll ..\..\_clib_bin\5.1
:eof
