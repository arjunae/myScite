@ECHO OFF
SET PATH=H:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

mingw32-make
rem if errorlevel 1 exit

mingw32-make clean
