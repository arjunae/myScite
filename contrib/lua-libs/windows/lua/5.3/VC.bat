@echo off
REM build lua, TKani arjunae@habmalnefrage.de LIC 3BSDClause
setlocal enabledelayedexpansion enableextensions
REM set PATH=%PATH%;"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
REM Params for arch (x86 or x64)
SET arch=x86
SET BUILDTYPE=release
REM
REM Init VisualStudio Environment
REM
echo.
echo Desired Target Architecture: %arch%
echo > vc.%arch%.%buildtype%.build

REM Handle situations with missing or defective vs installations.
REM search and init VS 17+ Build Tools from Installers Entries. For loops code based on various www sources
REM find MS Builds Key and read the line marked with "install" in it, get the installpath from that subkey and extract the Path from the entry.
:vsregsearch
for /F %%i in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\  /s /f "Visual Studio Build Tools"^|findstr "install"') DO (set installerPath=%%i ) 
if "!installerPath!" equ "" goto vsfilesearch
for /F "delims=" %%j in ('reg query !installerPath! /s /f "InstallLocation"^|findstr "Build"') DO (set rawString="%%j" )
REM retrieve the Path from the registry entries String and check if its valid.
SET vsPath=!rawString:*    InstallLocation    REG_SZ    =! & cd !vsPath! 
Echo calling BuildTools from registry entry !vsPath!
if %errorlevel% EQU 1 (goto vsfileSearch) else call VC\Auxiliary\Build\vcvarsall.bat %arch%

REM Optionally do a filesearch for vcvarsall.bat in %PATH% and program files x64 / x86. (compatible with all known versions, but slower) and recommend downloadlocation. 
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
cd src
echo.
echo Compiling lua
nmake /F mylua.mak all
del -F *.o *.obj *.lib
echo OK 
echo.
pause