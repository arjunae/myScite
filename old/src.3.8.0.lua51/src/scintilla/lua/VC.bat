@echo off
set arch=x86
echo Desired Architecture: %arch%
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"  %arch%

if "%1"=="DEBUG" set parameter1=DEBUG=1
REM set parameter1=DEBUG=1
cd src
nmake  /f mylua.mak dll
nmake  /f mylua.mak clean
move *.lib  ..\ 1>NUL 2>NUL
move *.dll ..\ 1>NUL 2>NUL
move *.exe ..\ 1>NUL 2>NUL
cd ..

echo :--------------------------
echo .... done ....
echo :--------------------------
pause