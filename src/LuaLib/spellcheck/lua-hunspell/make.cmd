@ECHO OFF
SET PATH=%PATH%;%~dp0%;
mingw32-make
if errorlevel 1 goto eof
 move /y lhunspell.dll spell.dll  2>NUL
del *.o 2>NUL
::mingw32-make clean
:eof

:: test lua hunspell build
call test-hspell.cmd

