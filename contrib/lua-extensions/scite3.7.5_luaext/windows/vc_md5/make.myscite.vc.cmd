@echo off
set LUA_PLAT=5.3
set LUA_LIB=scite.lib
set PLATFORM=x64

REM Overidable via params
if [%1] NEQ [] set LUA_PLAT=%1
REM if [%2] NEQ [] set LUA_LIB=%2
if [%3] NEQ [] set PLATFORM=%3
if PLATFORM==win32 set plat=x86
if PLATFORM==win64 set plat=x64
if ["%VCINSTALLDIR%"] equ [""] (set VCINSTALLDIR="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build")
call %VCINSTALLDIR%\vcvarsall.bat %platform%
PUSHD

REM cd src
nmake -nologo -f makefile.win clean
nmake -nologo -f makefile.win
if %errorlevel% gtr 0 goto eof
if exist src\core.dll move src\core.dll ..\clib\md5.dll
goto end

:eof
echo Make reported an error %errorlevel%
if [%1] EQU [] pause>NUL
exit %errorlevel%

:err_vc
echo Stop: Visual studio compile chain not found.
if [%1] EQU [] pause>NUL
exit %errorlevel%

:end
nmake -nologo -f makefile.win clean
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
if [%1] EQU [] pause>NUL
POPD


 