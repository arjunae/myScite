@echo off
:: Try to acquire a VisualStudio 14 Context
:: If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS

SET buildContext=14.0
SET arch=x86
::SET arch=x64

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
REM set parameter1=DEBUG=1
cd src
nmake  /f mylua.mak lib
nmake  /f mylua.mak clean

move *.lib ..\
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
