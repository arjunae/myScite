@echo off
if exist lxp.dll del /F /Q lxp.dll
mingw32-make lxp_lib
if errorlevel 1 goto eof
move /y lxp.dll lib\libexpat.dll

:eof
echo ----------------------- Fin ----------------------------------.
echo waiting  some time... (10sek)
ping 11.01.19.77 /n 1 /w 10000 >NUL