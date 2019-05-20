@chcp 65001 1>NUL
@echo off
:: MinGW Path has to be set, otherwise please define here:
:: set PATH=E:\MinGW\bin;%PATH%;

REM Sanity- Ensure MSys-MinGW availability / Determinate Architecture into %MAKE_ARCH%.
set MAKE_ARCH=""
where mingw32-make 1>NUL 2>NUL
if %ERRORLEVEL%==1 ( goto err_mingw )
mingw32-make --version | findstr /M i686 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] ( SET MAKE_ARCH=win32 && goto ok_mingw) 
mingw32-make --version | findstr /M x86_64 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] ( SET MAKE_ARCH=win64 && goto ok_mingw)
if %MAKE_ARCH% EQU "" goto err_mingw
:ok_mingw

echo  mingw build platform %MAKE_ARCH%

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
