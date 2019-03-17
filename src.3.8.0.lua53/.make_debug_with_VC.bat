@echo off
setlocal enabledelayedexpansion enableextensions

if exist src\vc.*.release.build choice /C YN /M "A VC Release Build has been found. Rebuild as Debug? "
if [%ERRORLEVEL%]==[2] (
  exit
) else if [%ERRORLEVEL%]==[1] (
  del src\vc.*.release.build 1>NUL 2>NUL
  cd src & del /S /Q *.dll *.exe *.lib .obj  *.pdb .res *.orig *.rej 1>NUL 2>NUL & cd ..
)

:: Try to acquire a VisualStudio 14 Context
:: If that fails, use systems highest available Version as defined via env var VS[xxx]COMNTOOLS

SET buildContext=14.0
SET arch=x86
rem SET arch=x64

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

set parameter1=DEBUG=1
echo.
echo ~~~~Build: Scintilla
cd src\scintilla\win32
nmake %parameter1% -f scintilla.mak
if errorlevel 1 goto :error

echo ~~~~Build: SciTE
cd ..\..\scite\win32
nmake %parameter1% -f scite.mak
if errorlevel 1 goto :error
echo.
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
echo.
echo ~~~~~ Copying Files to release...
if not exist ..\..\..\release md ..\..\..\release
move ..\bin\SciTE.exe ..\..\..\release
move ..\bin\SciLexer.dll ..\..\..\release
cd ..\..\..
echo . > src\vc.%arch%.debug.build
goto end

:error
pause

:end
PAUSE
EXIT
