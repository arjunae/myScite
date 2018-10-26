::...::..:::...::..::.:.::
::    SciTE Debug	::  
::...::..:::...::..::.:.::

@echo off
set PATH=E:\MinGW\bin;%PATH%;
set DEBUG=1
setlocal

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" .make_debug_with_MinGW.bat tiny
  EXIT
)
::mode 150,15
echo ::...::..:::...::..::.:.::
echo ::    SciTE Debug	::  
echo ::...::..:::...::..::.:.::

cd src\scintilla\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error

cd ..\..\scite\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error

echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

echo ... move to Release
copy ..\bin\SciTE.exe ..\..\..\..\SciTE.win64
copy ..\bin\SciLexer.dll ..\..\..\..\SciTE.win64

goto end

:error
pause

:end
cd ..\..
echo ------------------------------------------------
PAUSE
ECHO Waiting 33 seconds before closeing the window.
::Ping 11.1.19.77 -n 1 -w 33333
EXIT
