@echo off
set LUA_PLAT=5.3
set LUA_LIB=scilexer.lib
set PLAT=x86
if [%1] NEQ [] set LUA_PLAT=%1
if [%2] NEQ [] set LUA_LIB=%2

REM Ensure to have the compile Chain within Path. Use a default. 
if ["%VCINSTALLDIR%"] equ [""] (
set VS14="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\"
) else ( set VS14="%VCINSTALLDIR%")
set PATH=%VS14%;%VS14%\bin;%PATH%

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


 