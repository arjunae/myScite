@echo off
set LUA_PLAT=5.3
set LUA_LIB=scite.lib
REM set plat=x86
set plat=x64
if ["%VCINSTALLDIR%"] equ [""] (set VCINSTALLDIR="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build")
call %VCINSTALLDIR%\vcvarsall.bat  %plat%
PUSHD
cd src

if exist *.obj del *.obj
nmake -nologo -f makefile.myscite.vc
if %errorlevel% gtr 0 goto eof
if exist *.dll move *.dll ..\..\clib\
goto end

:eof
echo Make reported an error %errorlevel%
pause
exit %errorlevel%

:end
nmake -nologo -f makefile.myscite.vc clean
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
pause>NUL
POPD


 