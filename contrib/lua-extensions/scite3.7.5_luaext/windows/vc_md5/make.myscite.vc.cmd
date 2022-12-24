@echo off
setlocal enabledelayedexpansion enableextensions
set LUA_PLAT=5.3
set LUA_LIB=SciTe.lib
set arch=x86
rem set arch=x64
REM SET DEBUG=1
REM Ensure to have the compile Chain within Path. Use a default. 
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\Program Files" vcvarsall.bat 2^>NUL' ) DO echo %%i & call "%%i" %arch% )
if "!VSINSTALLDIR!" EQU "" (FOR /F "tokens=*" %%i IN ('where /r "c:\program files (x86)" vcvarsall.bat 2^>NUL'  ) DO echo %%i & call "%%i" %arch% )

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


 