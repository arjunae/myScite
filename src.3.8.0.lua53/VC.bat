@echo off
setlocal enabledelayedexpansion enableextensions
color f0
mode 190,30
if exist src\vc.*.debug.build choice /C YN /M "A VC Debug Build has been found. Rebuild as Release? "
if [%ERRORLEVEL%]==[2] (
goto en
) else if [%ERRORLEVEL%]==[1] (
cd src
del vc.*.debug.build 1>NUL 2>NUL
del /S /Q *.obj *.pdb *.a *.res *.orig *.rej *.dll *.exe 1>NUL 2>NUL
cd ..
)
REM Try to acquire a VisualStudio 14 Context
REM If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS
SET buildContext=14.0
SET arch=x86
REM SET arch=x64

echo About to build using:
call forcevcversion.cmd %buildContext%
if %errorlevel%==10 (
echo please build myScite withVisualStudio 2015
goto en
)
echo 
echo Target Architecture will be: %arch%
call "%VCINSTALLDIR%\vcvarsall.bat"  %arch%
if "%1"=="DEBUG" set parameter1=DEBUG=1

echo.
echo Compiling Scintilla
cd src\scintilla\win32
nmake %parameter1% -f scintilla.mak 2> %tmp%\buildLog
if [%errorlevel%] NEQ [0] goto err
echo Compiling SciTE 
cd ..\..\scite\win32
nmake %parameter1% -f scite.mak 2> %tmp%\buildLog
if [%errorlevel%] NEQ [0] goto err
echo.
echo. 
echo OK
echo 
REM Find and display currents build targets Platform
set DEST_TARGET=..\bin\SciTE.exe

REM
REM Now use this littl hack to look for a platform PE Signature at offset 120+
REM Should work compiler indepenent for uncompressed binaries.
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

set COPYFLAG=0
if [%DEST_PLAT%] EQU [win32] set COPYFLAG=1
if [%DEST_PLAT%] EQU [win64] set COPYFLAG=1
if %COPYFLAG% EQU 1 (
echo Copying Files to %cd%\build
if not exist ..\..\..\bin md ..\..\..\bin
copy ..\bin\SciTE.exe ..\..\..\bin
copy ..\bin\SciLexer.dll ..\..\..\bin
echo Targets platform: %DEST_PLAT%
) else (
echo  %DEST_TARGET% Platform: %DEST_PLAT%
)
cd ..\..\..
echo > src\vc.%arch%.release.build

:err
echo.
echo Stop: An Error %ERRORLEVEL% occured during the build
echo.
type %tmp%\buildLog  & echo.>%tmp%\buildLog
:en
echo.
echo OK
echo.
REM If the logfile still contains messages here, they are just warns
FOR /F "usebackq" %%A IN ('%tmp%\buildLog') DO set size=%%~zA 
if %size% equ set size=0 
if %size% gtr 1 (echo OK:There were warnings & type %tmp%\buildLog  & del /f %tmp%\buildLog)
del %tmp%\buildLog
pause