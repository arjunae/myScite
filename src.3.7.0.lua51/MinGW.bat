REM SciTE Prod      
@echo off
setlocal enabledelayedexpansion enableextensions
set BUILDTYPE=Release
REM Set Color and ScreenBuffer Size
color 08
reg add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 1111111 /f >NUL
REM MinGW Path has to be set in System Settings, otherwise please define here:
REM set PATH=E:\apps\msys64\mingw64\bin;%PATH%;
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
if not !instr!==!gcc_path! (SET MAKEARCH=win32) else ( SET MAKEARCH=win64) && goto :okMingw)
if %MAKEARCH% EQU "" goto :errMingw

:okMingw
REM use customized CMD Terminal
if "%1"=="" (
rem  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
rem  start "TinyTonC MD" %~nx0 %1 tiny  
)

echo.
echo SciTE Prod
echo. 
echo.
echo Environment %MAKEARCH% 
echo.

REM Sanity- Ask when trying to change between Debug and Release builds.
if exist src\mingw.*.debug.build choice /C YN /M "A MinGW Debug Build has been found. Rebuild as %BUILDTYPE%? "
if [%ERRORLEVEL%]==[2] (
  goto en
) else if [%ERRORLEVEL%]==[1] (
  cd src
  del mingw.*.debug.build 1>NUL 2>NUL
  del /S /Q *.dll *.exe *.res *.orig *.rej 1>NUL 2>NUL
  cd ..
)

if /I %BUILDTYPE%==debug set DEBUG=1
echo Compiling Scintilla
cd src\scintilla\win32
mingw32-make -j %NUMBER_OF_PROCESSORS% 2> %tmp%\buildLog
if [%errorlevel%] NEQ [0] goto err
echo Compiling SciTE
cd ..\..\scite\win32
mingw32-make -j %NUMBER_OF_PROCESSORS% 2>> %tmp%\buildLog
if [%errorlevel%] NEQ [0]  goto err
rem Now use this littl hack to look for a platform PE Signature at offset 120+
rem Should work compiler indepenent for uncompressed binaries.
rem Takes: DESTTARGET Value: Executable to be checked
rem Returns: PLAT Value: Either WIN32 or WIN64 
set DESTTARGET=..\bin\SciTE.exe
set off32=""
set off64=""
for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %DESTTARGET%') do (
  if [%%A] LEQ [200] SET DEST_PLAT=win32
  if [%%A] LEQ [200] SET OFFSET=%%A
)
for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %DESTTARGET%') do (
  if [%%A] LEQ [200] SET DEST_PLAT=win64
  if [%%A] LEQ [200] SET OFFSET=%%A
)
set COPYFLAG=0
if [%DEST_PLAT%] EQU [win32] set COPYFLAG=1
if [%DEST_PLAT%] EQU [win64] set COPYFLAG=1
if %COPYFLAG% EQU 1 (
echo Copying Files to %cd%\build
if not exist ..\..\..\bin md ..\..\..\bin
copy ..\bin\SciTE.exe ..\..\..\bin
set copyFailed=%ERRORLEVEL%
copy ..\bin\SciLexer.dll ..\..\..\bin
echo Targets platform: %DEST_PLAT%
) else (
echo  %DESTTARGET% Platform: %DEST_PLAT%
)

cd ..\..\..
echo > src\mingw.%DEST_PLAT%.%BUILDTYPE%.build
goto en

:errMingw
echo Error: MSYS2 MinGW Installation was not found or its not in your systems path.
echo.
echo Within MSYS2, utilize 
echo pacman -Sy mingw-w64-i686-toolchain
echo pacman -Sy mingw-w64-x86_64-toolchain
echo and add msys2/win32 or msys2/win64 to your systems path.
echo.

:err
echo.
echo Stop: An Error %ERRORLEVEL% occured during the build
echo.
type %tmp%\buildLog  & echo.>%tmp%\buildLog
:en
echo.
echo OK
echo.
REM If the logfile still contains messages here, they are just warns
FOR /F "usebackq" %%A IN ('%tmp%\buildLog') DO set size=%%~zA 
if %size% equ set size=0 
if %size% gtr 1 (echo OK:There were warnings & type %tmp%\buildLog)
del %tmp%\buildLog
pause
