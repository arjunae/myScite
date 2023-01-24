@echo off
REM build Scintilla/Scite, ThorstenKani marcedo@schmusemail.de LIC 3BSDClause
REM 31.12.2022 Sanity Checks, automatic recommendations and fixes
REM Fix mismatching buildtyes and missing directories, detect missing build chain and recommend download, write and analyse %tmp%/scitelog during build, increase screenbuffer size, one file for both release and debug builds
setlocal enabledelayedexpansion enableextensions
REM set PATH=%PATH%;"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
REM Params for arch (x86 or x64)
SET arch=x86
REM ScreenBuffer Size
REG add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 1111111 /f >NUL
set ReleaseDir="..\..\..\Bin"
pushd %cd%

REM
REM Decide for either a Debug, Release or Clean Build
REM Type D (Debug) or C (clean) during the start. Default set to R (Release)
REM
choice /T 1 /D R /C DRC /M "Create a Debug, a Release or a Clean build ? " >NUL
if %errorlevel% EQU 1 (SET BUILDTYPE=debug) 
if %errorlevel% EQU 2 (SET BUILDTYPE=release)
if %errorlevel% EQU 3  (SET BUILDTYPE=clean)
)
if /i %BUILDTYPE% NEQ "Release%" echo Creating !Buildtype!

:start
if exist %tmp%\scitelog.txt del /q %tmp%\scitelog.txt
echo. > %tmp%\build.tmp

REM
REM Sanity- Ask when trying to change between Debug and Release builds.
REM
if exist src\vc.*.*.build if not exist src\vc.*.%BUILDTYPE%.build (
   if "%buildtype%" neq "clean" choice /C YN /M "A different VC Build has been found. Rebuild as %BUILDTYPE%? "
   if [%ERRORLEVEL%]==[2] ( goto en ) else if [%ERRORLEVEL%]==[1] ( cd src\ & del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build 1>NUL 2>NUL & cd .. )
)

REM
REM Init VisualStudio Environment
REM
echo.
echo Desired Target Architecture: %arch%
echo > src\vc.%arch%.%buildtype%.build

REM Handle situations with missing or defective vs installations.
REM search and init VS 17+ from Installers Entries. For loops code based on various www sources
REM find MS Builds Key and read the line marked with "install" in it, get the installpath from that subkey and extract the Path from the entry.
:vsregsearch
for /F %%i in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\  /s /f "Visual Studio Build Tools"^|findstr "install"') DO (set installerPath=%%i ) 
if "!installerPath!" equ "" goto vsfilesearch
for /F "delims=" %%j in ('reg query !installerPath! /s /f "InstallLocation"^|findstr "Build"') DO (set rawString="%%j" )
REM retrieve the Path from the registry entries String and check if its valid.
SET vsPath=!rawString:*    InstallLocation    REG_SZ    =! & cd !vsPath! 
Echo calling BuildTools from registry entry !vsPath!
if %errorlevel% EQU 1 (goto vsfileSearch) else call VC\Auxiliary\Build\vcvarsall.bat %arch%

REM Optionally do a filesearch for vcvarsall.bat in %PATH% and program files x64 / x86. (compatible with older versions, but slower) and recommend downloadlocation. 
:vsfilesearch
Echo Searching vcvarsall.bat in Path, %ProgramFiles% and %ProgramFiles(x86)%
FOR /F "tokens=*" %%i IN ('where vcvarsall.bat 2^>NUL' ) DO echo %%i %arch% & call "%%i" %arch%
if /i "!WindowsSdkDir!"==""  FOR /F "tokens=*" %%i IN ('where /r "%ProgramFiles%"\ vcvarsall.bat 2^>NUL' ) DO echo %%i %arch% & call "%%i" %arch% 
if /i "!WindowsSdkDir!"==""  FOR /F "tokens=*" %%i IN ('where /r "%ProgramFiles(x86)%"\ vcvarsall.bat 2^>NUL'  ) DO echo %%i %arch% & call "%%i" %arch% 
if /i "!WindowsSdkDir!"=="" goto errVc
if "%BUILDTYPE%" EQU "clean" goto clean

REM check for callable RessourceCompiler and valid stdc++ headers 
where rc.exe 1>NUL 2>nul
if %ERRORLEVEL%==1 (echo "hmm. Ressource Compiler (SDK) not in Path.  ." goto errVc)
for /f "delims=; tokens=1" %%A in ("%include%") do (dir "%%A\cstring" >NUL)
if "%ERRORLEVEL%" EQU "1" (echo "hmm. Include Headers not found."  goto errVc )
popd

REM
REM Start the Build
REM
if "BUILDTYPE" EQU "debug" set parameter1=DEBUG=1
if exist %tmp%\nmakeErr del /q %tmp%\nmakeErr
echo.
echo Compiling Scintilla
cd src\scintilla\win32
if not exist ..\bin ( Echo scintilla\bin directory not found. Creating... & mkdir ..\bin )
REM nmake doesnt write its errlog to stdout, need to parse the /X param
nmake /X %tmp%\nmakeErr /NOLOGO %parameter1% -f scintilla.mak | "../../../uk.exe" %tmp%\build.tmp
findstr /n /c:"error"  %tmp%\nmakeErr
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling Scintilla & goto en
echo Compiling SciTE 
cd ..\..\scite\win32
if not exist ..\bin ( Echo scite\bin directory not found. Creating... & mkdir ..\bin )
nmake /X %tmp%\nmakeErr /NOLOGO %parameter1% -f scite.mak | "../../../uk.exe" -a %tmp%\build.tmp
findstr /n /c:"error" %tmp%\nmakeErr
if [%errorlevel%] EQU [0] echo Stop: An Error occured while compiling SciTe  & goto en
echo OK 
echo.

REM
REM Find and display currents build targets Platform
REM
REM Use this littl hack to look for a platform PE Signature at offset 120+
REM Should find it compiler independent for uncompressed binaries.
REM Takes: DEST_TARGET Value: Executable to be checked
REM Returns: PLAT Value: Either x86 or x64 
:find_platform
set DEST_TARGET=..\bin\SciTE.exe
set DEST_PLAT=UNDEFINED
if not exist %DEST_TARGET% (echo Error cant find build binary & goto en)
set off32="" & set off64=""
for /f "delims=:" %%A in ('findstr /o ".*PE..L." %DEST_TARGET%') do (
if [%%A] LEQ [200] (SET DEST_PLAT=x86 & SET OFFSET=%%A))
for /f "delims=:" %%A in ('findstr /o ".*PE..d." %DEST_TARGET%') do (
if [%%A] LEQ [200] (SET DEST_PLAT=x64 & SET OFFSET=%%A)
)
if /i [!DEST_PLAT!] EQU [UNDEFINED] (choice /C YN /M " Cant estimate Platform. Continue?" ) 
if %ERRORLEVEL% EQU 1 (goto copyFiles) else (goto en)
if /i [!DEST_PLAT!] NEQ [%ARCH%] (
choice /C YN /M " Platform mismatch found. Desired was %ARCH% and got %DEST_PLAt%. Rebuild ? " (
if [%ERRORLEVEL%]==[1] ( del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build & goto :start ) else (goto en )
)

:copyFiles
REM
REM Copy Files
REM
echo Copying Binaries from %cd%\bin
if not exist %ReleaseDir% mkdir %ReleaseDir%
if exist ..\bin\SciTE.exe  (copy ..\bin\SciTE.exe %ReleaseDir% >NUL ) else (echo Error: cant find build binaries & goto en )
if exist ..\bin\SciLexer.dll (copy ..\bin\SciLexer.dll %ReleaseDir% >NUL ) else (echo Error: cant find build binaries & goto en) 
echo Platform: %DEST_PLAT%
ECHO OK
cd ..\..\..
echo.

REM Show the logfile in case there were Warnings
findstr /n /c:"warning"   %tmp%\scitelog.txt >NUL
if %errorlevel% equ 0 (
choice /C YN /M " Show warnings ? "
if [%ERRORLEVEL%]==[0] ( findstr /n /c:"warning" %tmp%\build.tmp ))
goto en

:clean
echo Scintilla
cd src\scintilla\win32
nmake -f scintilla.mak clean 2>NUL
echo Scite
cd ..\..\scite\win32
nmake -f scite.mak clean 2>NUL
cd ..\..\
del *.*.build 1>NUL 2>NUL
echo.
goto en

:errVc
echo Error initing Vc. Please install "VS Build Tools for C++" and try again.  & start https://my.visualstudio.com/Downloads?q=studio+2015 & goto en )

:en
if exist %tmp%\nmakeErr del %tmp%\nmakeErr
pause
