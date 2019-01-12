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
echo.
where mingw32-make 1>NUL 2>NUL
if %ERRORLEVEL%==1 (
 echo Error: MSYS2/MinGW Installation was not found or its not in your systems path.
 echo.
 echo Within MSYS2, utilize 
 echo pacman -Sy mingw-w64-i686-toolchain
 echo pacman -Sy mingw-w64-x86_64-toolchain
 echo and add msys2/win32 or msys2/win64 to your systems path.
 echo.
 pause
exit
)

echo ~~~~Build: Scintilla
cd src\scintilla\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error
echo.
echo ~~~~Build: SciTE
cd ..\..\scite\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error
echo.
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

echo ~~~~~ Copying Files to release...
copy ..\bin\SciTE.exe ..\..\..\release
copy ..\bin\SciLexer.dll ..\..\..\release

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
