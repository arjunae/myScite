@ECHO OFF

set PLAT=x64
set LUA_PLAT=5.3
rem set LUA_LIB=scilexer.lib
set LUA_LIB=scite.lib

REM Ensure to have the compile Chain within Path. Use a default. 
if ["%VCINSTALLDIR%"] equ [""] (set VCINSTALLDIR="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build")
call %VCINSTALLDIR%\vcvarsall.bat  %plat%
PUSHD

call vcvarsall.bat %PLAT%
cd src\luasocket
nmake -f makefile.myscite.vc socket.lib
if %errorlevel% gtr 0 goto eof
move *.lib ..\
nmake -f makefile.myscite.vc clean
cd ..
nmake -f makefile.myscite.vc ssl.dll
if %errorlevel% gtr 0 goto eof
if exist ssl.dll move ssl.dll ..\..\clib\
nmake -f makefile.myscite.vc clean
goto end

:eof
echo Make reported an error %errorlevel%
pause
exit %errorlevel%

:end
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
pause>NUL
POPD
