@echo off
REM for a debug build use:  make_debug_with_VC.bat
setlocal enabledelayedexpansion enableextensions

if exist src\vc.*.debug.build choice /C YN /M "A VC Debug Build has been found. Rebuild as Release? "
if [%ERRORLEVEL%]==[2] (
  exit
) else if [%ERRORLEVEL%]==[1] (
  cd src
  del vc.*.debug.build 1>NUL 2>NUL
  del /S /Q *.obj *.pdb *.a *.res *.orig *.rej *.dll *.exe 1>NUL 2>NUL
  cd ..
)
:: Try to acquire a VisualStudio 14 Context
:: If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS

SET buildContext=14.0
SET arch=x86
SET arch=x64

:: #############

echo ~~ About to build using:
call force_vc_version.cmd %buildContext%
if %errorlevel%==10 (
 echo please build myScite withVisualStudio 2015
	exit /b %errorlevel%
)
echo ~~
echo Target Architecture will be: %arch%
call "%VCINSTALLDIR%\vcvarsall.bat"  %arch%

if "%1"=="DEBUG" set parameter1=DEBUG=1

echo.
echo ~~~~Build: Scintilla
cd src\scintilla\win32
nmake %parameter1% -f scintilla.mak
if [%errorlevel%] NEQ [0] goto :error

echo ~~~~Build: SciTE
cd ..\..\scite\win32
nmake %parameter1% -f scite.mak
if [%errorlevel%] NEQ [0] goto :error
echo.
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
REM Find and display currents build targets Platform
set DEST_TARGET=..\bin\SciTE.exe
call :find_platform
set COPYFLAG=0
if [%DEST_PLAT%] EQU [win32] set COPYFLAG=1
if [%DEST_PLAT%] EQU [win64] set COPYFLAG=1
if %COPYFLAG% EQU 1 (
echo ~~~~~ Copying Files to build...
if not exist ..\..\..\build md ..\..\..\build
copy ..\bin\SciTE.exe ..\..\..\build
copy ..\bin\SciLexer.dll ..\..\..\build
echo .... Targets platform: %DEST_PLAT% ......
) else (
echo  %DEST_TARGET% Platform: %DEST_PLAT%
)

cd ..\..\..
echo > src\vc.%arch%.release.build
goto end

:error
echo Stop: An Error %ERRORLEVEL% occured during the build.
pause

:end
PAUSE
EXIT

REM --------------------------------------------------
REM Now use this littl hack to look for a platform PE Signature at offset 120+
REM Should work compiler independent for uncompressed binaries.
REM Takes: DEST_TARGET Value: Executable to be checked
REM Returns: PLAT Value: Either WIN32 or WIN64 
:find_platform
set off32=""
set off64=""

for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %DEST_TARGET%') do (
  if [%%A] LEQ [200] SET DEST_PLAT=win32
  if [%%A] LEQ [200] SET OFFSET=%%A
)

for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %DEST_TARGET%') do (
  if [%%A] LEQ [200] SET DEST_PLAT=win64
  if [%%A] LEQ [200] SET OFFSET=%%A
)
exit /b 0
:end_sub
