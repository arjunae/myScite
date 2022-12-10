@echo off
REM	SciTE Clean
REM use customized CMD Terminal
REM if "%1"=="" (
REM  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
REM  start "TinyTonCMD" %~nx0 %1 tiny
REM  EXIT
REM )
mode 150,18
echo Scintilla
cd src\scintilla\win32
nmake -f scintilla.mak clean 2>NUL
echo Scite
cd ..\..\scite\win32
nmake -f scite.mak clean 2>NUL
cd ..\..\
del mingw.*.*.build 1>NUL 2>NUL
echo.
echo OK
