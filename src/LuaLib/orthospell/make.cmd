@ECHO OFF
SET PATH=H:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

mingw32-make
if errorlevel 1 goto eof

if exist luahunspell.cpp ( move /y luahunspell.dll spell.dll  2>NUL )
if exist luahunspell.orthospell.cpp ( move /y luahunspell.dll hunspell.dll  2>NUL )
del *.o 2>NUL
::mingw32-make clean
:eof

:: test lua hunspell build
call test-hspell.cmd

