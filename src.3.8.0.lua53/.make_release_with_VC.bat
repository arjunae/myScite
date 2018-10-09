@echo off
REM for make debug version use:  make_with_VC.bat DEBUG
ECHO VC_Build temporary not possible.
PAUSE
exit

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

cd src\scintilla\win32
nmake %parameter1% -f scintilla.mak
if errorlevel 1 goto :error

cd ..\..\scite\win32
nmake %parameter1% -f scite.mak
if errorlevel 1 goto :error

echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

REM This littl hack looks for a platform PE Signature at offset 120+
REM Should work compiler independent for uncompressed binaries.
REM Offsets MSVC/MINGW==120 BORLAND==131 PaCKERS >xxx
REM -1 suggests that a binary is compressed

set PLAT=""
set file=..\bin\SciTE.exe

for /f "delims=:" %%A in ('findstr /o "^.*PE..L." "%file%"') do ( 
  if %%A LEQ 200 (SET PLAT=WIN32) ELSE (SET PLAT=NIL) 
  if %%A LEQ 200 (SET OFFSET=%%A) ELSE (SET OFFSET=-1)
)

for /f "delims=:" %%B in ('findstr /o "^.*PE..d." "%file%"') do (
  if %%B LEQ 200 (SET PLAT=WIN64) ELSE (SET PLAT=NIL)
  if %%B LEQ 200 (SET OFFSET=%%B) ELSE (SET OFFSET=-1)
)

echo .... Targets platform [%PLAT%] ......
If [%PLAT%]==[WIN32] (
move ..\bin\SciTE.exe ..\..\..\release
move ..\bin\SciLexer.dll ..\..\..\release
)

If [%PLAT%]==[WIN64] (
move ..\bin\SciTE.exe ..\..\..\release
move ..\bin\SciLexer.dll ..\..\..\release
)

goto end

:error
pause

:end
cd ..\..
PAUSE
EXIT
