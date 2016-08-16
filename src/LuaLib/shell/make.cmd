@ECHO OFF
SET PATH=C:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

mingw32-make all
if errorlevel 1 goto eof
goto eof
mingw32-make clean
:eof
