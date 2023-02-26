@echo off
REM build Scintilla/Scite, ThorstenKani t.kani@gmx.net
setlocal enabledelayedexpansion enableextensions
Mode 200,49
REM Path has to be set in System Settings, otherwise please define here:
REM set PATH=E:\tools\msys64\mingw32\bin;%PATH%;
REM Set Color and ScreenBuffer Size
reg add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 330000 /f >NUL
set ReleaseDir="..\..\..\Bin"
REM Clear logfile
echo.>%tmp%\tmp

REM
REM Decide for either a Debug, Release or Clear Build
REM Type D (Debug) or C (clear) during the start. Default set to R (Release)
REM
choice /T 1 /D R /C DRC /M "Create a Debug, a Release or clear build ? " >NUL
if %errorlevel% EQU 1 (SET BUILDTYPE=debug) 
if %errorlevel% EQU 2 (SET BUILDTYPE=release)
if %errorlevel% EQU 3  (SET BUILDTYPE=clear)
)
if /i %BUILDTYPE% NEQ "Release%" echo Creating !Buildtype!

REM
REM Sanity- Ensure MSys-MinGW availability / write currently configured Architecture into %ARC%.
REM
set ARC=""
where gcc 1>NUL 2>NUL
if %ERRORLEVEL%==1 (goto :fail_inst)
gcc -dumpmachine | findstr /M i686 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] (SET ARC=x86&& goto :ok) 
gcc -dumpmachine | findstr /M x86_64 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] (SET ARC=x64&& goto :ok)
REM Otherwise, try to deduct arch from gccs Pathname (searches for string 32)
if %ARC% EQU "" ( for /F "tokens=1,2* delims= " %%a in ('where gcc') do ( Set gcc_path=%%a && set instr=!gcc_path:32=! )
if not !instr!==!gcc_path! (SET ARC=x86) else (SET ARC=x64) && goto :ok)
if %ARC% EQU "" goto :fail_inst
:ok
echo.

echo Environment %ARC% 
echo.
IF /i "%BUILDTYPE%" EQU "clear" goto clear_stuff

REM
REM Start the actual build.
REM
if /I %BUILDTYPE%==debug set DEBUG=1
echo Compiling Scintilla
cd src\scintilla\win32
if not exist ..\bin ( Echo scintilla\bin directory not found. Creating... & md ..\bin )
mingw32-make -j %NUMBER_OF_PROCESSORS% 2>%tmp%\tmp
if [%errorlevel%] NEQ [0] goto fail
echo Compiling SciTE
cd ..\..\scite\win32
if not exist ..\bin ( Echo scintilla\bin directory not found. Creating... & md ..\bin )
mingw32-make -j %NUMBER_OF_PROCESSORS% 2>%tmp%\tmp
if [%errorlevel%] NEQ [0]  goto fail

REM
REM Find binaries Arc
REM
REM Use this littl hack to look for a platform PE Signature at offset 120+
REM Should find it compiler independent for uncompressed binaries.
REM Takes: DEST Value: Binary
REM Returns: DEST_ARC Value: Either x86 or x64 
:find_platform
set DEST=..\bin\SciTE.exe
set DEST_ARC=UNDEFINED
if not exist %DEST% (echo Error no build binary found & goto clear_stuff)
set off32="" & set off64=""
for /f "delims=:" %%A in ('findstr /o ".*PE..L." %DEST%') do (
if [%%A] LEQ [200] (SET DEST_ARC=x86& SET OFFSET=%%A))
for /f "delims=:" %%A in ('findstr /o ".*PE..d." %DEST%') do (
if [%%A] LEQ [200] (SET DEST_ARC=x64& SET OFFSET=%%A)
)
if /i [!DEST_ARC!] EQU [UNDEFINED] (choice /C YN /M " Platform estimation failed. Continue?" ) 
if %ERRORLEVEL% EQU 0 (goto copy_binaries) else (goto clear_stuff)
if /i [!DEST_ARC!] NEQ [!ARC!] (
choice /C YN /M " Platform mismatch found. Desired was %ARC% and got %DEST_ARC%. Rebuild ? " (
if [%ERRORLEVEL%]==[1] ( del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build & goto :start ) else (goto clear_stuff )
)

REM
REM Copy Binaries
REM
:copy_binaries
echo Copying Binaries from %cd%\bin
if not exist %ReleaseDir% mkdir %ReleaseDir%
if exist ..\bin\SciTE.exe  (copy ..\bin\SciTE.exe %ReleaseDir% >NUL ) else (echo Binaries not found & Pause & goto :eof )
if exist ..\bin\SciLexer.dll (copy ..\bin\SciLexer.dll %ReleaseDir% >NUL ) else (echo Binaries not found & Pause & goto :eof) 
echo Platform: %DEST_ARC%
ECHO OK
)
cd ..\..\..
del /q src\*.build 2>Nul
echo. > src\%DEST_ARC%.%BUILDTYPE%.build
goto :eof


:fail_inst
echo MSYS2 Installation was not found or its not in your systems path.
echo.
echo Within MSYS2, utilize 
echo pacman -Sy mingw-w64-i686-toolchain
echo pacman -Sy mingw-w64-x86_64-toolchain
echo and add msys2/win32 or msys2/win64 to your systems path.
echo.

:fail
echo.
echo Stop: Errorlevel %ERRORLEVEL% occured
echo.

:clear_stuff
echo Scintilla
cd src\scintilla\win32
mingw32-make clean 2>NUL
echo Scite
cd ..\..\scite\win32
mingw32-make clean 2>NUL
cd ..\..\
del *.*.build 1>NUL 2>NUL
pause
goto :eof

:ok2
REM findstr /n /c:"warning" %tmp%\tmp 1>NUL
REM if %errorlevel% equ 0 (
REM choice /C EW /M " There where warnings. "
REM if [%ERRORLEVEL%]==[3] (findstr /n /c:"warning" %tmp%\tmp 1>NUL >2NUL))
pause
