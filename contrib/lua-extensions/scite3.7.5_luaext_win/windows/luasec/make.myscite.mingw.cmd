@ECHO OFF
REM Init Vars
set LUA_PLAT=5.3
set LUA_LIB=-lscilexer

REM Defined here via config.txt 
FOR /f "tokens=1,2 delims==" %%G in (..\config.txt) do (
	if %%G==LUA_PLAT set LUA_PLAT=%%H
	if %%G==LUA_LIB set LUA_LIB=%%H
)

REM Overidable via params
if [%1] NEQ [] set LUA_PLAT=%1
if [%2] NEQ [] set LUA_LIB=%2

pushd
cd src\luasocket
mingw32-make --makefile makefile.myscite.mingw
if %errorlevel% gtr 0 goto eof
if exist *.a move *.a ..\..\
mingw32-make --makefile makefile.myscite.mingw clean
cd ..\..\
mingw32-make --makefile makefile.myscite.mingw windows 
if %errorlevel% gtr 0 goto eof
mingw32-make --makefile makefile.myscite.mingw clean
if exist *.dll move *.dll ..\clib\
goto end

:eof
echo Make reported an error %errorlevel%
pause
exit %errorlevel%

:end
echo ----------------------- Fin ----------------------------------.
echo Waiting some time. Please press your favorite Key when done.
if [%1] EQU [] pause>NUL
POPD
