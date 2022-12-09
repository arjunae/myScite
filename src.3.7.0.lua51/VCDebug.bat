@echo off
REM for a Release build use:  make_release_with_VC.bat
setlocal enabledelayedexpansion enableextensions
SET buildContext=14.0
SET arch=x86
REM SET arch=x64
REM color f0
REM mode 190,30
REM ScreenBuffer Size
reg add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 1111111 /f >NUL
echo. > %tmp%\scitelog.txt
if exist src\vc.*.release.build choice /C YN /M "A VC Release Build has been found. Rebuild as Debug? "
if [%ERRORLEVEL%]==[2] (
goto en
) else if [%ERRORLEVEL%]==[1] (
cd src
del vc.*.release.build 1>NUL 2>NUL
del /S /Q *.obj *.pdb *.lib *.res *.orig *.rej *.dll *.exe 1>NUL 2>NUL
cd ..
)

REM Try to acquire a VisualStudio 14 Context
REM If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS
echo About to build using:
call forcevcversion.cmd %buildContext%
if %errorlevel%==10 (
echo please build myScite withVisualStudio >= 2015
goto en
)
echo.
echo Target Architecture will be: %arch%
call "%VCINSTALLDIR%\vcvarsall.bat"  %arch%
set parameter1=DEBUG=1
echo.
echo Compiling Scintilla
cd src\scintilla\win32
nmake /NOLOGO %parameter1% -f scintilla.mak | "../../wtee.exe" %tmp%\scitelog.txt
if [%errorlevel%] NEQ [0] echo Stop: An Error occured while parsing Scintillas makefile & goto en
findstr /n /c:"error"  %tmp%\scitelog.txt
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling Scintilla & goto en
echo Compiling SciTE 
cd ..\..\scite\win32
nmake /NOLOGO %parameter1% -f scite.mak | "../../wtee.exe" -a %tmp%\scitelog.txt
if [%errorlevel%] NEQ [0] echo Stop: An Error occured while parsing SciTes makefile & goto en
findstr /n /c:"error"  %tmp%\scitelog.txt
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling SciTe & goto en
echo.
echo.
echo OK 
echo.

REM Find and display currents build targets Platform
REM
REM Now use this littl hack to look for a platform PE Signature at offset 120+
REM Should work compiler indepenent for uncompressed binaries.
REM Takes: DEST_TARGET Value: Executable to be checked
REM Returns: PLAT Value: Either WIN32 or WIN64
set DEST_TARGET=..\bin\SciTE.exe
set off32=""
set off64=""
for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %DEST_TARGET%') do (
if [%%A] LEQ [200] SET DEST_PLAT=x32
if [%%A] LEQ [200] SET OFFSET=%%A
)
for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %DEST_TARGET%') do (
if [%%A] LEQ [200] SET DEST_PLAT=x64
if [%%A] LEQ [200] SET OFFSET=%%A
)
if %DEST_PLAT% NEQ %ARCH% echo Platform mismatch found. Desired was %ARCH% and got %DEST_PLAT%. Please clean old objectfiles and rebuild & goto en
REM
REM Copy Files
REM
set COPYFLAG=0
if [%DEST_PLAT%] EQU [win32] set COPYFLAG=1
if [%DEST_PLAT%] EQU [win64] set COPYFLAG=1
if %COPYFLAG% EQU 1 (
echo Copying Binaries from %cd%\bin
if not exist ..\..\..\bin md ..\..\..\bin
if exist ..\bin\SciTE.exe  (copy ..\bin\SciTE.exe ..\..\..\bin >NUL ) else (goto en)
if exist ..\bin\SciLexer.dll (copy ..\bin\SciLexer.dll ..\..\..\bin >NUL ) else (goto en) 
echo Platform: %DEST_PLAT%
ECHO OK
)
cd ..\..\..
echo > src\vc.%arch%.debug.build
echo.
:warn
REM Show the logfile in case there were Warnings
findstr /n /c:"warning"   %tmp%\scitelog.txt
if %errorlevel% equ 0 (Echo There were Warnings & findstr /n /c:"warning" %tmp%\scitelog.txt)
:en
pause
