@chcp 65001 1>NUL
@echo off
REM  MinGW Path has to be set, otherwise please define here:
REM set PATH=E:\MinGW\bin;%PATH%;
 set PATH=E:\apps\msys64\mingw32\bin;%PATH%;
REM Sanity- Ensure MSys-MinGW availability / Determinate Architecture into %MAKEARCH%.
set MAKEARCH=""
where gcc 1>NUL 2>NUL
if %ERRORLEVEL%==1 (goto :errMingw)
gcc -dumpmachine | findstr /M i686 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] (SET MAKEARCH=win32 && goto :okMingw) 
gcc -dumpmachine | findstr /M x86_64 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] (SET MAKEARCH=win64 && goto :okMingw)
REM Otherwise, try to deduct make arch from gccs Pathname
if %MAKEARCH% EQU "" ( for /F "tokens=1,2* delims= " %%a in ('where gcc') do ( Set gcc_path=%%a && set instr=!gcc_path:mingw32=! )
if not !instr!==!gcc_path! (SET MAKEARCH=x32) else ( SET MAKEARCH=x64) && goto :okMingw)
if %MAKEARCH% EQU "" goto :errMingw

:okMingw
REM use customized CMD Terminal
if "%1"=="" (
rem  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
rem  start "TinyTonC MD" %~nx0 %1 tiny  
)

REM Start Clean
del /f clib\*.dll 1>NUL 2>NUL

REM Init Vars with some defaults
set LUA_PLAT=5.3
set LUA_LIB=-lscite

REM Define them here 
FOR /f "tokens=1,2 delims==" %%G in (config.txt) do (
	if %%G==LUA_PLAT set LUA_PLAT=%%H
	if %%G==LUA_LIB set LUA_LIB=%%H
)

REM Iterate through all SubDirs containing mingw or vc make batches
for /R  %%A in (.) Do (
	pushd %%A
	if exist *mingw.cmd (
		echo [OK]	[%%A]
	 	call make.myscite.mingw.cmd %LUA_PLAT% %LUA_LIB%
		if %errorlevel% gtr 0 goto end
	) else (
		if exist *vc.cmd call make.myscite.vc.cmd %LUA_PLAT% %LUA_LIB% %MAKE_ARCH%
	)
	popd
)
goto end

:err_mingw
echo Error: MSYS2/MinGW Installation was not found or its not in your systems path.
echo.
echo Within MSYS2, utilize 
echo pacman -Sy mingw-w64-i686-toolchain
echo pacman -Sy mingw-w64-x86_64-toolchain
echo and add msys2/win32 or msys2/win64 to your systems path.
echo.
pause
exit
:end_sub

:end
Pause
