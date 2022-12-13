@echo off
setlocal enabledelayedexpansion enableextensions
set arch=x86
REM use customized CMD Terminal
REM if "%1"=="" (
REM  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
REM  start "TinyTonCMD" %~nx0 %1 tiny
REM  EXIT
REM )
mode 150,18

REM
REM Init VisualStudio Environment
REM
REM check for nmake, optionally search and init VS in program files x64 / x86 
REM manually delete the trash if appropiate
where /Q nmake.exe
if %ERRORLEVEL% EQU 1 (
FOR /F "tokens=*" %%i IN ('where /r "c:\Program Files" vcvarsall.bat 2^>NUL' ) DO echo %%i & call "%%i" %arch% ) 
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\program files (x86)" vcvarsall.bat 2^>NUL'  ) DO echo %%i & call "%%i" %arch% )
if "!VSINSTALLDIR!" EQU "" cd src\ & del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist & goto en
)

echo Scintilla
cd src\scintilla\win32
nmake -f scintilla.mak clean 
echo Scite
cd ..\..\scite\win32
nmake -f scite.mak clean 2>NUL
cd ..\..\
del *.*.build 1>NUL 2>NUL
echo.
:en
echo OK
ping localhost -n 2 > nul