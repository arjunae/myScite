@ECHO OFF
::SET PATH=H:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

PUSHD

:: Clean object Files to ensure we dont link with outdated ones
::if exist *.o mingw32-make --makefile makefile.myscite.mingw clean

mingw32-make --makefile makefile.myscite.mingw %1 win32
if errorlevel 1 goto :eof

mingw32-make --makefile makefile.myscite.mingw clean
if exist lexers\*.dll move lexers\*.dll ..\clib\

:eof
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
pause>NUL
POPD
