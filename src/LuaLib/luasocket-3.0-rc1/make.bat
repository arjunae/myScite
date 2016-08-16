@echo off

cd src
mingw32-make mingw
move /Y socket*.dll ..\..\_clib_bin\socket
move /Y mime*.dll ..\..\_clib_bin\mime

del  *.o  2>NUL
cd ..
