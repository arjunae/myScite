@ECHO OFF
echo --- Creates a lua ressource lib which simply points to SciTE.exe or scilexer.dll ---
PUSHD
mingw32-make --makefile makefile.myscite libscite.a
::mingw32-make --makefile makefile.myscite libscilexer.a
::mingw32-make lua.dll
if %errorlevel% gtr 1 goto eof
POPD
REM move *.dll ..\clib\ 2>NUL
REM move *.a ..\clib\ 2>NUL
mingw32-make --makefile makefile.myscite clean

:eof
echo ----------------------- Fin ----------------------------------.
pause