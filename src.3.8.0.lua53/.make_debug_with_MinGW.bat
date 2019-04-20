::...::..:::...::..::.:.::
::    SciTE Debug   ::  
::...::..:::...::..::.:.::

@echo off
setlocal enabledelayedexpansion enableextensions
set BUILD_TYPE=Debug

:: MinGW Path has to be set, otherwise please define here:
:: set PATH=E:\MinGW\bin;%PATH%;

REM Sanity- Ensure MSys/MinGW availability / Determinate Architecture into %MAKE_ARCH%.
set MAKE_ARCH=""
where mingw32-make 1>NUL 2>NUL
if %ERRORLEVEL%==1 (
  goto :err_mingw 
) else if [%ERRORLEVEL%]==[0] (
  mingw32-make --version | findstr /M x86_64 1>NUL 2>NUL
  if [%ERRORLEVEL%]==[0] ( SET MAKE_ARCH=win64 )
  mingw32-make --version | findstr /M i686 1>NUL 2>NUL
  if [%ERRORLEVEL%]==[0] ( SET MAKE_ARCH=win32 )
)
if %MAKE_ARCH% EQU "" goto :err_mingw

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" %~nx0 %1 tiny
  EXIT
)

echo ::..::..:::..::..::.:.::
echo ::    SciTE Debug     ::
echo ::..::..:::..::..::.:.::
echo.


echo ~~~~Build Environment: %MAKE_ARCH% 
echo.

REM Sanity- Ask when trying to change between Debug and Release builds.
if exist src\mingw.*.release.build choice /C YN /M "A MinGW Release Build has been found. Rebuild as %BUILD_TYPE%? "
if [%ERRORLEVEL%]==[2] (
  exit
) else if [%ERRORLEVEL%]==[1] (
  cd src
  del mingw.*.release.build 1>NUL 2>NUL
  del /S /Q *.dll *.exe *.res *.orig *.rej 1>NUL 2>NUL
  cd ..
)

if /I %BUILD_TYPE%==Debug set DEBUG=1
echo ~~~~Build: Scintilla
cd src\scintilla\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if [%errorlevel%] NEQ [0] goto :error
echo.
echo ~~~~Build: SciTE
cd ..\..\scite\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if [%errorlevel%] NEQ [0] goto :error
echo.
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

REM Find and display currents build targets Platform
set DEST_TARGET=..\bin\SciTE.exe
call :find_platform
set COPYFLAG=0
if [%DEST_PLAT%] EQU [win32] set COPYFLAG=1
if [%DEST_PLAT%] EQU [win64] set COPYFLAG=1
if %COPYFLAG% EQU 1 (
echo ~~~~~ Copying Files to build...
if not exist ..\..\..\build md ..\..\..\build
copy ..\bin\SciTE.exe ..\..\..\build
copy ..\bin\SciLexer.dll ..\..\..\build
echo .... Targets platform: %DEST_PLAT% ......
) else (
echo  %DEST_TARGET% Platform: %DEST_PLAT%
)

cd ..\..\..
echo > src\mingw.%DEST_PLAT%.%BUILD_TYPE%.build
goto end

:error
echo Stop: An Error %ERRORLEVEL% occured during the build. 

:end
PAUSE
EXIT

::--------------------------------------------------
:: Now use this littl hack to look for a platform PE Signature at offset 120+
:: Should work compiler independent for uncompressed binaries.
:: Takes: DEST_TARGET Value: Executable to be checked
:: Returns: PLAT Value: Either WIN32 or WIN64 
:find_platform
set off32=""
set off64=""

for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %DEST_TARGET%') do (
  if [%%A] LEQ [200] SET DEST_PLAT=win32
  if [%%A] LEQ [200] SET OFFSET=%%A
)

for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %DEST_TARGET%') do (
  if [%%A] LEQ [200] SET DEST_PLAT=win64
  if [%%A] LEQ [200] SET OFFSET=%%A
)
exit /b 0
:end_sub

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