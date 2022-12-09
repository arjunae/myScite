@echo off
setlocal enabledelayedexpansion enableextensions
set VCINSTALLDIR="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
set BUILDTYPE=Debug
SET buildContext=14.0
SET arch=x86
REM SET arch=x64
rem color f0
rem mode 200,30
REM ScreenBuffer Size
reg add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 1111111 /f >NUL
echo. > %tmp%\scitelog.txt

REM
REM Sanity- Ask when trying to change between Debug and Release builds.
REM
if exist src\vc.*.*.build if not exist src\vc.*.%BUILDTYPE%.build choice /C YN /M "A different VC Build has been found. Rebuild as %BUILDTYPE%? "
if [%ERRORLEVEL%]==[2] (
  goto en
) else if [%ERRORLEVEL%]==[1] (
  cd src
  del vc.*.*.build 1>NUL 2>NUL
  del /S /Q *.dll *.exe *.res *.orig *.rej 1>NUL 2>NUL
  cd ..
)

REM
REM Start the Build
REM
REM Try to acquire a VisualStudio 14 Context
REM If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS
rem call forcevcversion.cmd %buildContext%
if %errorlevel%==10 (
echo please build myScite with VisualStudio Version greater or equal 2015
goto en
)
echo.
echo SciTE %BUILDTYPE% 
echo Target Architecture will be: %arch%
call %VCINSTALLDIR%\vcvarsall.bat  %arch%
if "%1"=="DEBUG" set parameter1=DEBUG=1
echo.
echo Compiling Scintilla
cd src\scintilla\win32
nmake /NOLOGO %parameter1% -f scintilla.mak | "../../wtee.exe" %tmp%\scitelog.txt
findstr /n /c:"error"  %tmp%\scitelog.txt
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling Scintilla & goto en
echo Compiling SciTE 
cd ..\..\scite\win32
nmake /NOLOGO %parameter1% -f scite.mak | "../../wtee.exe" -a %tmp%\scitelog.txt
findstr /n /c:"error"  %tmp%\scitelog.txt
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling SciTe & goto en
echo OK 
echo.

REM
REM Find and display currents build targets Platform
REM
REM Use this littl hack to look for a platform PE Signature at offset 120+
REM Should work compiler independent for uncompressed binaries.
REM Takes: DEST_TARGET Value: Executable to be checked
REM Returns: PLAT Value: Either x86 or x64 
:find_platform
set DEST_TARGET=..\bin\SciTE.exe
set off32=""
set off64=""
for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %DEST_TARGET%') do (
if [%%A] LEQ [200] SET DEST_PLAT=x86
if [%%A] LEQ [200] SET OFFSET=%%A
)
for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %DEST_TARGET%') do (
if [%%A] LEQ [200] SET DEST_PLAT=x64
if [%%A] LEQ [200] SET OFFSET=%%A
) 
if %DEST_PLAT% NEQ %ARCH% echo Platform mismatch found. Desired was %ARCH% and got %DEST_PLAT%. Please remove old objectfiles and rebuild & goto en

REM
REM Copy Files
REM
echo Copying Binaries from %cd%\bin
if not exist ..\..\..\bin md ..\..\..\bin
if exist ..\bin\SciTE.exe  (copy ..\bin\SciTE.exe ..\..\..\bin >NUL ) else (goto en)
if exist ..\bin\SciLexer.dll (copy ..\bin\SciLexer.dll ..\..\..\bin >NUL ) else (goto en) 
echo Platform: %DEST_PLAT%
ECHO OK
cd ..\..\..
echo > src\vc.%arch%.%buildtype%.build
echo.
:warn
REM Show the logfile in case there were Warnings
findstr /n /c:"warning"   %tmp%\scitelog.txt >NUL
if %errorlevel% equ 0 (Echo There were Warnings & findstr /n /c:"warning" %tmp%\scitelog.txt)
:en
pause
