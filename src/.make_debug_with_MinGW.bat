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

cd 3.7.0\scintilla\win32
mingw32-make
if errorlevel 1 goto :error

cd ..\..\scite\win32
mingw32-make
if errorlevel 1 goto :error

echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
::--------------------------------------------------
:: This littl hack looks for a platform PE Signature at offset 120+
:: Should work compiler independent for uncompressed binaries.
set PLAT=""
set off32=""
set off64=""

for /f "delims=:" %%A in ('findstr /o "^.*PE..L.. " ..\bin\SciTE.exe') do ( set off32=%%A ) 
if %off32%==120 set PLAT=WIN32

for /f "delims=:" %%A in ('findstr /o "^.*PE..d.. " ..\bin\SciTE.exe') do ( set off64=%%A ) 
if %off64%==120 set PLAT=WIN64

echo .... Targets platform [%PLAT%] ......
If [%PLAT%]==[WIN32] (
echo .... move to SciTE.win32 ......
move ..\bin\SciTE.exe ..\..\..\..\SciTE.win32
move ..\bin\SciLexer.dll ..\..\..\..\SciTE.win32
)

If [%PLAT%]==[WIN64] (
echo ... move to SciTE.win64
move ..\bin\SciTE.exe ..\..\..\..\SciTE.win64
move ..\bin\SciLexer.dll ..\..\..\..\SciTE.win64
)

goto end

:error
pause

:end
cd ..\..
echo ------------------------------------------------
ECHO Waiting 33 seconds before closeing the window.
Ping 11.1.19.77 -n 1 -w 33333
EXIT
