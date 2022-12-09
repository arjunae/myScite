@ECHO OFF

REM set plat=x86
set plat=x64
set LUA_PLAT=5.3
set LUA_LIB=scite.lib
PUSHD

REM Ensure to have the compile Chain within Path. Use a default. 
if ["%VCINSTALLDIR%"] equ [""] (set VCINSTALLDIR="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build")
call %VCINSTALLDIR%\vcvarsall.bat  %plat%
cd src
if exist *.obj nmake -f makefile.myscite.vc clean
nmake -f makefile.myscite.vc socket.dll
if %errorlevel% gtr 0 goto eof
nmake -f makefile.myscite.vc mime.dll
if %errorlevel% gtr 0 goto eof

if exist socket.dll move socket.dll ..\..\clib\
if exist mime.dll move mime.dll ..\..\clib\
goto end

:eof
echo Make reported an error %errorlevel%
pause
exit %errorlevel%

:end
nmake -f makefile.myscite.vc clean
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
pause>NUL
POPD
