@chcp 65001 1>NUL
@echo off

REM Start Clean
del /f clib\*.dll 1>NUL

REM Init Vars with some defaults
set LUA_PLAT=5.3
set LUA_LIB=-lscilexer

REM Define them here 
FOR /f "tokens=1,2 delims==" %%G in (config.txt) do (
	if %%G==LUA_PLAT set LUA_PLAT=%%H
	if %%G==LUA_LIB set LUA_LIB=%%H
)

REM Iterate through all SubDirs containing mingw make batches
for /R  %%A in (.) Do (
	pushd %%A
	if exist *mingw.cmd (
		echo [%%A]
		call make.myscite.mingw.cmd %LUA_PLAT% %LUA_LIB%
		if %errorlevel% gtr 0 goto end
	)
	popd
)

:end
Pause