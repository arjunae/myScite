@echo off

::Adapt appropriately so ensuring to have the compile Chain within Path. 
set VS14=%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\VC
set PATH=%VS14%;%VS14%\bin;%PATH%

::set INCLUDE=%VS14%\INCLUDE;C:\Program Files (x86)\Windows Kits\10\include\10.0.10240.0\ucrt;C:\Program Files (x86)\Windows Kits\8.1\include\shared;C:\Program Files (x86)\Windows Kits\8.1\include\um;C:\Program Files (x86)\Windows Kits\8.1\include\winrt;
::set LIB=%VS14%\LIB\amd64;C:\Program Files (x86)\Windows Kits\10\lib\10.0.10240.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\8.1\lib\winv6.3\um\x64;
::set VS140COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\

call vcvarsall.bat x86
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


 