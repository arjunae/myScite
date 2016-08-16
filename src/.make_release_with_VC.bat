@echo off
REM for make debug version use: 
REM >make_with_VC.bat DEBUG

setlocal
FOR /f "tokens=2 delims==" %%a IN ('SET ^| FINDSTR /b /i /r /c:"VS[0-9]*COMNTOOLS"') DO SET Tools=%%a
if "%Tools%"=="" (
	echo VS COMNTOOLS Environment NOT FOUND!
	exit /b 1
)
call "%Tools%vsvars32.bat"

if "%1"=="DEBUG" set parameter1=DEBUG=1

cd 3.6.4\scintilla\win32
nmake %parameter1% -f scintilla.mak
if errorlevel 1 goto :error

cd ..\..\scite\win32
nmake %parameter1% -f scite.mak
if errorlevel 1 goto :error

::copy /Y ..\bin\SciTE.exe ..\..\..\pack\
::copy /Y ..\bin\SciLexer.dll ..\..\..\pack\
goto end

:error
pause

:end
cd ..\..
