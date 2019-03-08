::...::..:::...::..::.:.::
::    SciTE Prod   ::  
::...::..:::...::..::.:.::

@echo off
setlocal enabledelayedexpansion enableextensions
set DEBUG=1
set PLAT=""
set PLAT_TARGET=""

::set PLAT_TARGET=..\bin\SciTE.exe
::call :find_platform
::If [%PLAT%]==[WIN32] ()

:: MinGW Path has to be set, otherwise please define here:
::set PATH=E:\MinGW\bin;%PATH%;

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" %~nx0 %1 tiny
  EXIT
)

echo ::..::..:::..::..::.:.::
echo ::    SciTE Debug     ::
echo ::..::..:::..::..::.:.::
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
mingw32-make  -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error
echo.
echo ~~~~Build: SciTE
cd ..\..\scite\win32
mingw32-make  -j %NUMBER_OF_PROCESSORS%
::if errorlevel 1 goto :error
echo.
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

REM Find and display currents build targets Platform
set PLAT_TARGET=..\bin\SciTE.exe
call :find_platform
echo .... Targets platform [%PLAT%] ......
echo ~~~~~ Copying Files to release...
If [%PLAT%]==[WIN32] (
echo .... move to SciTE.win32 ......
if not exist ..\..\..\release md ..\..\..\release
copy ..\bin\SciTE.exe ..\..\..\release
copy ..\bin\SciLexer.dll ..\..\..\release
)

If [%PLAT%]==[WIN64] (
echo ... move to SciTE.win64
if not exist ..\..\..\release md ..\..\..\release
copy ..\bin\SciTE.exe ..\..\..\release
copy ..\bin\SciLexer.dll ..\..\..\release
)

goto end

:error
pause

:end
cd ..\..
PAUSE
EXIT

::--------------------------------------------------
:: Now use this littl hack to look for a platform PE Signature at offset 120+
:: Should work compiler independent for uncompressed binaries.
:: Takes: PLAT_TARGET Value: Executable to be checked
:: Returns: PLAT Value: Either WIN32 or WIN64 
:find_platform
set off32=""
set off64=""

for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %PLAT_TARGET%') do ( set off32=%%A ) 
if %off32%==120 set PLAT=WIN32

for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %PLAT_TARGET%') do ( set off64=%%A ) 
if %off64%==120 set PLAT=WIN64
exit /b 0
:end_sub
