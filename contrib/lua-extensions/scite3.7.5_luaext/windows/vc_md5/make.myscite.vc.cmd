@echo off
set LUA_PLAT=5.3
set LUA_LIB=scilexer.lib

set plat=x86
::set plat=x64

REM Ensure to have the compile Chain within Path. Use a default. 
if ["%VCINSTALLDIR%"] equ [""] (
set VS14="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\"
) else ( set VS14="%VCINSTALLDIR%")
set PATH=%VS14%;%VS14%\bin;%PATH%
PUSHD

REM cd src
call vcvarsall.bat %plat%
nmake -nologo -f makefile.win clean
nmake -nologo -f makefile.win
if %errorlevel% gtr 0 goto eof
if exist src\core.dll move src\core.dll ..\clib\md5.dll
goto end

:eof
echo Make reported an error %errorlevel%
pause
exit %errorlevel%

:end
nmake -nologo -f makefile.win clean
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
pause>NUL
POPD


 