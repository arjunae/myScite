@echo off
REM build Scintilla/Scite, ThorstenKani marcedo@schmusemail.de
setlocal enabledelayedexpansion enableextensions
REM MinGW Path has to be set in System Settings, otherwise please define here:
 set PATH=E:\apps\msys64\mingw32\bin;%PATH%;
set ReleaseDir="..\..\..\Reg"
REM Set Color and ScreenBuffer Size
reg add HKCU\Console\%%SystemRoot%%_system32_cmd.exe\ScreenBufferSize /t REG_DWORD /d 1111111 /f >NUL
REM Clear logfile
echo.>%tmp%\sciteLog

REM
REM Decide for either a Debug, Release or Clean Build
REM Type D (Debug) or C (clean) during the start. Default set to R (Release)
REM
choice /T 1 /D R /C DRC /M "Create a Debug, a Release or a Clean build ? " >NUL
if %errorlevel% EQU 1 (SET BUILDTYPE=debug) 
if %errorlevel% EQU 2 (SET BUILDTYPE=release)
if %errorlevel% EQU 3  (SET BUILDTYPE=clean)
)
if /i %BUILDTYPE% NEQ "Release%" echo Creating !Buildtype!

REM
REM Sanity- Ensure MSys-MinGW availability / write currently configured Architecture into %MAKEARCH%.
REM
set MAKEARCH=""
where gcc 1>NUL 2>NUL
if %ERRORLEVEL%==1 (goto :errMingw)
gcc -dumpmachine | findstr /M i686 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] (SET MAKEARCH=x86&& goto :okMingw) 
gcc -dumpmachine | findstr /M x86_64 1>NUL 2>NUL
if [%ERRORLEVEL%]==[0] (SET MAKEARCH=x64&& goto :okMingw)
REM Otherwise, try to deduct make arch from gccs Pathname (searches for string wingw32)
if %MAKEARCH% EQU "" ( for /F "tokens=1,2* delims= " %%a in ('where gcc') do ( Set gcc_path=%%a && set instr=!gcc_path:mingw32=! )
if not !instr!==!gcc_path! (SET MAKEARCH=x86) else (SET MAKEARCH=x64) && goto :okMingw)
if %MAKEARCH% EQU "" goto :errMingw
:okMingw
echo.

echo ::...::..:::...::..::.:.::
echo     SciTE %BUILDTYPE%    
echo ::...::..:::...::..::.:.::
echo Environment %MAKEARCH% 
echo.
IF /i "%BUILDTYPE%" EQU "clean" goto cleanStuff

REM
REM Sanity- Ask when trying to change between Debug and Release builds.
REM
if exist src\mingw.*.*.build if not exist src\mingw.*.%BUILDTYPE%.build (
   choice /C YN /M "A different MinGW Build has been found. Rebuild as %BUILDTYPE%? "
   if [%ERRORLEVEL%]==[2] ( goto en ) else if [%ERRORLEVEL%]==[1] ( cd src\ & del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build 1>NUL 2>NUL & cd .. )
)

REM
REM Start the actual build.
REM
if /I %BUILDTYPE%==debug set DEBUG=1
echo Compiling Scintilla
cd src\scintilla\win32
if not exist ..\bin ( Echo scintilla\bin directory not found. Creating... & md ..\bin )
mingw32-make -j %NUMBER_OF_PROCESSORS% 2> %tmp%\SciTeLog
if [%errorlevel%] NEQ [0] goto err
echo Compiling SciTE
cd ..\..\scite\win32
if not exist ..\bin ( Echo scintilla\bin directory not found. Creating... & md ..\bin )
mingw32-make -j %NUMBER_OF_PROCESSORS% 2>> %tmp%\SciteLog
if [%errorlevel%] NEQ [0]  goto err

REM
REM Find and display currents build targets Platform
REM
REM Use this littl hack to look for a platform PE Signature at offset 120+
REM Should find it compiler independent for uncompressed binaries.
REM Takes: DEST_TARGET Value: Executable to be checked
REM Returns: PLAT Value: Either x86 or x64 
:find_platform
set DEST_TARGET=..\bin\SciTE.exe
set DEST_PLAT=UNDEFINED
if not exist %DEST_TARGET% (echo Error cant find build binary & goto en)
set off32="" & set off64=""
for /f "delims=:" %%A in ('findstr /o ".*PE..L." %DEST_TARGET%') do (
if [%%A] LEQ [200] (SET DEST_PLAT=x86& SET OFFSET=%%A))
for /f "delims=:" %%A in ('findstr /o ".*PE..d." %DEST_TARGET%') do (
if [%%A] LEQ [200] (SET DEST_PLAT=x64& SET OFFSET=%%A)
)
if /i [!DEST_PLAT!] EQU [UNDEFINED] (choice /C YN /M " Cannot estimate Platform. Continue?" ) 
if %ERRORLEVEL% EQU 0 (goto copyFiles) else (goto en)
if /i [!DEST_PLAT!] NEQ [!MAKEARCH!] (
choice /C YN /M " Platform mismatch found. Desired was %MAKEARCH% and got %DEST_PLAT%. Rebuild ? " (
if [%ERRORLEVEL%]==[1] ( del /s /q *.exe *.o *.obj *pdb *.dll *.res *.map *.exp *.lib *.plist *.build & goto :start ) else (goto en )
)


REM
REM Copy Files
REM
:copyFiles
echo Copying Binaries from %cd%\bin
if not exist %ReleaseDir% mkdir %ReleaseDir%
if exist ..\bin\SciTE.exe  (copy ..\bin\SciTE.exe %ReleaseDir% >NUL ) else (echo Error: cant find build binaries & goto en )
if exist ..\bin\SciLexer.dll (copy ..\bin\SciLexer.dll %ReleaseDir% >NUL ) else (echo Error: cant find build binaries & goto en) 
echo Platform: %DEST_PLAT%
ECHO OK
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
type %tmp%\scitelog
goto :en

:cleanStuff
echo Scintilla
cd src\scintilla\win32
mingw32-make clean 2>NUL
echo Scite
cd ..\..\scite\win32
mingw32-make clean 2>NUL
cd ..\..\
del *.*.build 1>NUL 2>NUL

:en
echo.
REM Show the logfile in case there were Warnings
findstr /n /c:"warning"   %tmp%\scitelog.txt >NUL
if %errorlevel% equ 0 (
choice /C YN /M " There where warnings. Display them ? "
if [%ERRORLEVEL%]==[1] ( findstr /n /c:"warning" %tmp%\scitelog.txt ))
pause
