@echo off

REM Ensure to have the compile Chain within Path. Use a default. 
if ["%VCINSTALLDIR%"] equ [""] (
set VS14="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\"
) else ( set VS14="%VCINSTALLDIR%")
set PATH=%VS14%;%VS14%\bin;%PATH%

call vcvarsall.bat %PLAT%
if exist *.obj del *.obj

nmake -nologo -f makefile.myscite.vc all
if errorlevel 1 pause

if exist *.lib move *.lib ..\..\..\
if exist *.dll del /F /Q *.dll 
nmake -nologo -f makefile.myscite.vc clean

:eof
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
::pause>NUL
POPD


 