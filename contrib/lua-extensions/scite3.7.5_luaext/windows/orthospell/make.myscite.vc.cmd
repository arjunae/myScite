@echo off
set LUA_PLAT=5.3
set LUA_LIB=scite.lib
set PLAT=x64
if [%1] NEQ [] set LUA_PLAT=%1
if [%2] NEQ [] set LUA_LIB=%2

if ["%VCINSTALLDIR%"] equ [""] (set VCINSTALLDIR="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build")
call %VCINSTALLDIR%\vcvarsall.bat  %plat%
cd src
PUSHD 1.4.1\src\win_api\
call make.myscite.vc.bat
POPD

if exist *.obj del *.obj
call vcvarsall.bat %PLAT%
nmake -nologo -f makefile.myscite.vc
if errorlevel 1 goto eof

if exist hunspell.dll move hunspell.dll ..\..\clib\
goto end

:eof
echo Make reported an error %errorlevel%
pause
exit %errorlevel%

:end
nmake -nologo -f makefile.myscite.vc clean
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
if [%1] EQU [] pause>NUL
POPD


 