@echo off
REM for make debug version use: 
REM >make_with_VC.bat DEBUG

::set VS140COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\
set VS900COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\Tools\

::set PATH=C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin;%PATH%
setlocal

::--------------------------------------------------
FOR /f "tokens=2 delims==" %%a IN ('SET ^| FINDSTR /b /i /r /c:"VS[0-9]*COMNTOOLS"') DO SET Tools=%%a
if "%Tools%"=="" (
	echo VS COMNTOOLS Environment NOT FOUND!
	exit /b 1
)
::call "%Tools%vcvars32.bat"
::--------------------------------------------------

::call vcvars32.bat
::call vcvarsall.bat amd64
call vcvarsall.bat x86

if "%1"=="DEBUG" set parameter1=DEBUG=1
REM set parameter1=DEBUG=1

cd 3.7.0\scintilla\win32
nmake %parameter1% -f scintilla.mak
if errorlevel 1 goto :error

cd ..\..\scite\win32
nmake %parameter1% -f scite.mak
if errorlevel 1 goto :error

echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
::--------------------------------------------------
:: This littl hack looks for a platform PE Signature at offset 120+
:: Should work compiler independent for uncompressed binaries.
set PLAT=""
set off32=""
set off64=""

for /f "delims=:" %%A in ('findstr /o "^.*PE..L.. " ..\bin\SciTE.exe') do ( set off32=%%A ) 
if %off32%==120 set PLAT=WIN32

for /f "delims=:" %%A in ('findstr /o "^.*PE..d.. " ..\bin\SciTE.exe') do ( set off64=%%A ) 
if %off64%==120 set PLAT=WIN64

echo .... Targets platform [%PLAT%] ......
If [%PLAT%]==[WIN32] (
echo .... move to SciTE.win32 ......
move ..\bin\SciTE.exe ..\..\..\..\SciTE.win32
move ..\bin\SciLexer.dll ..\..\..\..\SciTE.win32
)

If [%PLAT%]==[WIN64] (
echo ... move to SciTE.win64
::move ..\bin\SciTE.exe ..\..\..\..\SciTE.win64
move ..\bin\SciLexer.dll ..\..\..\..\SciTE.win64
)

goto end

:error

:end
pause
cd ..\..
