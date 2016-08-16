@ECHO OFF
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

CD /D "%~dp0"
windres -o resfile.o toolbar.rc
IF ERRORLEVEL 1 pause

ld --strip-all --dll -o win.dll resfile.o
REM gcc -s -shared -o cool.dll resfile.o
IF ERRORLEVEL 1 pause

DEL resfile.o

