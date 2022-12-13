@echo off
REM 2022/12 Sanity Checks and automatic recommations and fixes
REM Fix mismatching buildtyes and missing directories, detect missing build chain and recommend download, write and analyse %tmp%/scitelog during build, increase screenbuffer size
setlocal enabledelayedexpansion enableextensions
REM set PATH=%PATH%;"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
REM Params for arch x86 or x64, Params vor Buildtype: release or debug
SET arch=x86
SET BUILDTYPE=debug
rem color f0
rem mode 200,30
REM ScreenBuffer Size
reg add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 1111111 /f >NUL
:start
echo. > %tmp%\scitelog.txt

REM
REM Sanity- Ask when trying to change between Debug and Release builds.
REM
if exist src\vc.*.*.build if not exist src\vc.*.%BUILDTYPE%.build choice /C YN /M "A different VC Build has been found. Rebuild as %BUILDTYPE%? "
if [%ERRORLEVEL%]==[2] (
  goto en
) else if [%ERRORLEVEL%]==[1] (
  cd src\ & del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build 1>NUL 2>NUL
  cd ..
)

REM
REM Init VisualStudio Environment
REM
echo.
echo SciTE %BUILDTYPE% 
echo Desired Target Architecture: %arch%
REM  check for compiler, optionally search and init VS from %PATH% and program files x64 / x86 
where /Q cl.exe
if %ERRORLEVEL% EQU 0 goto initOK
FOR /F "tokens=*" %%i IN ('where vcvarsall.bat 2^>NUL' ) DO echo %%i & call "%%i" %arch% )
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\Program Files" vcvarsall.bat 2^>NUL' ) DO echo %%i & call "%%i" %arch% )
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\program files (x86)" vcvarsall.bat 2^>NUL'  ) DO echo %%i & call "%%i" %arch% )
if "!VSINSTALLDIR!" EQU "" echo Error initing vcvarsall.bat. Please install "Build Tools for VS" and try again. ) & start https://visualstudio.microsoft.com/de/visual-cpp-build-tools/ & goto en )
:initOK

REM
REM Start the Build
REM
if "BUILDTYPE" EQU "debug" set parameter1=DEBUG=1
echo.
echo Compiling Scintilla
cd src\scintilla\win32
if not exist ..\bin ( Echo scintilla\bin directory not found. Creating... & md ..\bin )
nmake /NOLOGO %parameter1% -f scintilla.mak | "../../../wtee.exe" %tmp%\scitelog.txt
findstr /n /c:"error"  %tmp%\scitelog.txt
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling Scintilla & goto en
echo Compiling SciTE 
cd ..\..\scite\win32
if not exist ..\bin ( Echo scite\bin directory not found. Creating... & md ..\bin )
nmake /NOLOGO %parameter1% -f scite.mak | "../../../wtee.exe" -a %tmp%\scitelog.txt
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
set off32="" & set off64=""
for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %DEST_TARGET%') do (
if [%%A] LEQ [200] SET DEST_PLAT=x86 & SET OFFSET=%%A )
for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %DEST_TARGET%') do (
if [%%A] LEQ [200] SET DEST_PLAT=x64 & SET OFFSET=%%A )
if %DEST_PLAT% NEQ %ARCH% (
choice /C YN /M " Platform mismatch found. Desired was %ARCH% and got %DEST_PLAT%. Rebuild ? " (
if [%ERRORLEVEL%]==[1] ( del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build & goto :start ) else (goto en )
)

REM
REM Copy Files
REM
echo Copying Binaries from %cd%\bin
if not exist ..\..\..\bin md ..\..\..\bin
if exist ..\bin\SciTE.exe  (copy ..\bin\SciTE.exe ..\..\..\bin >NUL ) else (echo Error: cant find build binaries & goto en )
if exist ..\bin\SciLexer.dll (copy ..\bin\SciLexer.dll ..\..\..\bin >NUL ) else (echo Error: cant find build binaries & goto en) 
echo Platform: %DEST_PLAT%
ECHO OK
cd ..\..\..
echo > src\vc.%arch%.%buildtype%.build
echo.
:warn
REM Show the logfile in case there were Warnings
findstr /n /c:"warning"   %tmp%\scitelog.txt >NUL
if %errorlevel% equ 0 (
choice /C YN /M " There where warnings. Display them ? "
if [%ERRORLEVEL%]==[0] ( findstr /n /c:"warning" %tmp%\scitelog.txt ))
:en
pause
