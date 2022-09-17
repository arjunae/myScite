@echo off
REM for a Release build use:  make_release_with_VC.bat
setlocal enabledelayedexpansion enableextensions

SET buildContext=14.0
SET arch=x86
REM SET arch=x64

REM #############

if exist src\vc.*.release.build choice /C YN /M "A VC Release Build has been found. Rebuild as Debug? "
if [%ERRORLEVEL%]==[2] (
goto end
) else if [%ERRORLEVEL%]==[1] (
cd src
del vc.*.release.build 1>NUL 2>NUL
del /S /Q *.obj *.pdb *.lib *.res *.orig *.rej *.dll *.exe 1>NUL 2>NUL
cd ..
)

REM Try to acquire a VisualStudio 14 Context
REM If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS

echo ~~ About to build using:
call forcevcversion.cmd %buildContext%
if %errorlevel%==10 (
echo please build myScite withVisualStudio 2015
goto end
)
echo.
echo Target Architecture will be: %arch%
call "%VCINSTALLDIR%\vcvarsall.bat"  %arch%
set parameter1=DEBUG=1

echo.
echo Build: Scintilla
cd src\scintilla\win32
nmake %parameter1% -f scintilla.mak
if [%errorlevel%] NEQ [0] echo Stop: An Error %ERRORLEVEL% occured during the build. & goto end

echo Build: SciTE
cd ..\..\scite\win32
nmake %parameter1% -f scite.mak
if [%errorlevel%] NEQ [0] echo Stop: An Error %ERRORLEVEL% occured during the build. & goto end
echo.
echo.
echo OK 
echo.

REM Find and display currents build targets Platform
set DEST_TARGET=..\bin\SciTE.exe

REM
REM Now use this littl hack to look for a platform PE Signature at offset 120+
REM Should work compiler independent for uncompressed binaries.
REM Takes: DEST_TARGET Value: Executable to be checked
REM Returns: PLAT Value: Either WIN32 or WIN64 
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

set COPYFLAG=0
if [%DEST_PLAT%] EQU [win32] set COPYFLAG=1
if [%DEST_PLAT%] EQU [win64] set COPYFLAG=1
if %COPYFLAG% EQU 1 (
FOR /F "tokens=* USEBACKQ" %%D IN (`pwd`) DO (set curPath=%D)
echo Copying Files to %curPath%/build
if not exist ..\..\..\build md ..\..\..\build
copy ..\bin\SciTE.exe ..\..\..\build
copy ..\bin\SciLexer.dll ..\..\..\build
echo .... Targets platform: %DEST_PLAT% ......
) else (
echo  %DEST_TARGET% Platform: %DEST_PLAT%
)

cd ..\..\..
echo > src\vc.%arch%.debug.build

:end
PAUSE