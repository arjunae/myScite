@echo off
setlocal enabledelayedexpansion enableextensions
REM set LUA_PLAT=5.1
REM set LUA_LIB=SciTe.lib
set arch=x86
rem set arch=x64
REM SET DEBUG=1
REM Ensure to have the compile Chain within Path. Use a default. 
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\Program Files" vcvarsall.bat 2^>NUL' ) DO echo %%i & call "%%i" %arch% )
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\program files (x86)" vcvarsall.bat 2^>NUL'  ) DO echo %%i & call "%%i" %arch% )
PUSHD

cd src
nmake  /f mylua.mak exeScilexer
nmake  /f mylua.mak clean
move *.lib  ..\ 1>NUL 2>NUL
move *.dll ..\ 1>NUL 2>NUL
move *.exe ..\ 1>NUL 2>NUL
cd ..

echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
pause