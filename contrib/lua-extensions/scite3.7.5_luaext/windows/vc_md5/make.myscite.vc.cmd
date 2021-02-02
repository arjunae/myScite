@echo off
set LUA_PLAT=5.3
set LUA_LIB=scite.lib
set PLATFORM=x86

REM Overidable via params
if [%1] NEQ [] set LUA_PLAT=%1
REM if [%2] NEQ [] set LUA_LIB=%2
if [%3] NEQ [] set PLATFORM=%3

if PLATFORM==win32 set plat=x86
if PLATFORM==win64 set plat=x64

REM Ensure to have the compile Chain within Path. Use a default. 
if ["%VCINSTALLDIR%"] equ [""] (
set VS14="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\"
) else ( set VS14="%VCINSTALLDIR%")
set PATH=%VS14%;%VS14%\bin;%PATH%
PUSHD

where vcvarsall.bat 1>NUL 2>NUL
if %ERRORLEVEL%==1 ( goto :err_vc )

REM cd src
call vcvarsall.bat %plat%
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


 