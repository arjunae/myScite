@echo off

::
::Provides a specific Visual Studio Build Environment. Requires only a version Number aks 14.0
:: Sets vars: VCINSTALLDIR, VS[xx]COMMNTOOLS, VisualStudioVersion WindowsLibPath , WindowsSdkDir , WindowsSDKLibVersion, WindowsSDKVersion
::
:: USAGE: 
::		force_vc_version.cmd (VC Version)
::		force_vc_version.cmd 14.0
::		%VCINSTALLDIR%\vcvarsall.bat x86
::
:: Mar 2018, Marcedo@habMalNeFrage.de
::

set dumpMode=0 && set vcVer=%1 && set dupeCheck="" && set anyVer=0 && set okFlag=10

if "%1"=="anyVer" set anyVer=1
if "%1"=="anyver" set anyVer=1
if "%1"=="default" set anyVer=2
if "%1" equ "" (
echo -- Version 20180316 / Marcedo@habMalNeFrage.de 
echo -- USAGE:
echo -- force_vc_version.cmd [VC Version Number] / anyVer / default
echo	-- force_vc_version.cmd 14.0
echo	-- force_vc_version.cmd default
echo.
echo -- Listing installed Versions --
set dumpMode=1
)

REM First we look for an installed default BuildChain
REM Return that one if the first param equals either "default" or "anyVer"
FOR /f "tokens=2 delims==" %%a IN ('SET ^| FINDSTR /b /i /r /c:"VS[0-9]*COMNTOOLS"') DO SET vcPath=%%a
if %anyVer% geq 1 if "%vcPath%" neq "" (
	echo "%vcPath%"
	call "%vcPath%\vcvarsqueryregistry.bat"
	set okFlag=0
	goto :end
)

REM #... User wants a specific Ver- so we search for any installed Visual studio versions...
for /F "tokens=* " %%i in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\CLSID /d /s /f vcbuild.dll  ') DO (
	REM #... then, iterate through any found Installation Pathes 
	for /F "tokens=1,2* " %%j in ('@echo "%%i" ^| findstr vcbuild.dll ') DO (
		set dupeCheck=vcDllPath && set vcDllPath=%%l
		REM #... now, parse each entry 
		if %dupeCheck% neq %%l	call :set_vcPath
		if %anyVer%==1 goto :end
	)
)
goto :end


:set_vcPath
REM ~~ found a Path entry, so call its environment setup script. 
set vcPath=%vcDllPath:vc\vcpackages\vcbuild.dll" =%
set vcPath=%vcPath%common7\tools

if %dumpMode%==1 echo "%vcPath%"
if %anyVer%==1 set vcVer="Visual Studio"

REM ~~ write VCs Installation Path to env var VCINSTALLDIR
echo %vcPath% | findstr %vcVer% 1>NUL 2>NUL
if [%errorlevel%] == [0] (
	echo "%vcPath%"
	call "%vcPath%\vcvarsqueryregistry.bat"
	set okFlag=0
)

set vcDllPath=&& set dupeCheck=&& set vcPath=

exit /b %errorlevel%
:end_sub

REM ~~ Returns 0 on success or 10 if no VC Installation could be found  
:end
::echo %okFlag%
exit /b %okFlag%

REM Appendix - ClassIDs of VisualStudio "vcbuild.dll" versions  
REM VS2010 : 0e763a5b-d3c8-44f0-aa28-51ed82a999d2
REM VS2011 : ce4a73f0-f9ff-447c-a5a4-d6c9b6cdb067
REM VS2014 : ad8259dd-ea93-4200-a424-a8a362559d69

