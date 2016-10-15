::...::..:::...::..::.:.::
::    SciTE Debug	::  
::...::..:::...::..::.:.::

@echo off
set PATH=E:\MinGW\bin;%PATH%;
set DEBUG=1
setlocal

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ...\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" .make_debug_with_MinGW.bat tiny
  EXIT
)
::mode 150,15
echo ::...::..:::...::..::.:.::
echo ::    SciTE Debug	::  
echo ::...::..:::...::..::.:.::

cd 3.6.7\scintilla\win32
mingw32-make
if errorlevel 1 goto :error

cd ..\..\scite\win32
mingw32-make
if errorlevel 1 goto :error
echo ------------------------------------------------
copy /Y ..\bin\SciTE.exe ..\..\..\..\SciTE.win32
copy /Y ..\bin\SciLexer.dll ..\..\..\..\SciTE.win32
goto end

:error
pause

:end
cd ..\..
echo ------------------------------------------------
ECHO Waiting 33 seconds before closeing the window.
Ping 11.1.19.77 -n 1 -w 33333
EXIT
