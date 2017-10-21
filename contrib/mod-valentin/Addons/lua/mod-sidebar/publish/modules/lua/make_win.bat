@echo off

:: Publish-Module for Lua - Win version
:: (c) Valentin Schmidt 2016

:: config
set LUA_DIR=C:\dev\Lua\5.1

:: args
set APPNAME=%~1
set LUA_LIBS=%~2
set LUA_CLIBS=%~3
set LUA_DLLS=%~4
set CREATE_ZIP=%~5
set APPROOT_FILES=%~6

:: start
set SRC=.
set STANDALONE_DIR=%cd%\..\%APPNAME%_standalone_win
set APP_DIR=%STANDALONE_DIR%\%APPNAME%
set LUA_CORE=wlua.exe lua5.1.dll lua51.dll
set ZIP_CMD="%~dp0..\..\bin\zip.exe"

::set RMDIR_CMD=rmdir /S /Q
set RMDIR_CMD="%~dp0..\..\bin\recycle.exe" -f

:: remove previous version if existing
IF EXIST "%APP_DIR%" %RMDIR_CMD% "%APP_DIR%" >nul 2>&1

:: make app folder
mkdir "%APP_DIR%"
if errorlevel 1 (echo ERROR: could not create publish folder for project & exit 1)

:: copy app.exe
copy "%~dp0app.exe" "%APP_DIR%\%APPNAME%.exe"
if errorlevel 1 (echo ERROR: could not copy app.exe & exit 2)

:: make data folder
mkdir "%APP_DIR%\data"
if errorlevel 1 (echo ERROR: could not create data folder & exit 3)

:: copy project folder
echo.
echo Copying project folder into data...
xcopy %SRC%\* "%APP_DIR%\data\" /s /exclude:%~dp0excludes+%~dp0excludes_win
if errorlevel 1 (echo ERROR: could not copy project folder & exit 4)

:: move AppRoot files to top folder
for %%f in (%APPROOT_FILES%) do (
  move "%APP_DIR%\data\%%f" "%APP_DIR%\"
  if errorlevel 1 (echo ERROR: could not move file %%f to app root folder & exit 5)
)

:: copy Lua core binaries
echo.
echo Copying Lua core binaries into data...
mkdir "%APP_DIR%\data\bin"
for %%l in (%LUA_CORE%) do (
  copy "%LUA_DIR%\%%l" "%APP_DIR%\data\bin\"
  if errorlevel 1 (echo ERROR: could not copy core binary %%l & exit 5)
)

:: copy Lua clibs
mkdir "%APP_DIR%\data\bin\clibs"
for %%l in (%LUA_CLIBS%) do (
  IF EXIST "%LUA_DIR%\clibs\%%l.dll" copy "%LUA_DIR%\clibs\%%l.dll" "%APP_DIR%\data\bin\clibs\"
  IF EXIST "%LUA_DIR%\clibs\%%l" xcopy /s "%LUA_DIR%\clibs\%%l" "%APP_DIR%\data\bin\clibs\%%l\"
  if errorlevel 1 (echo ERROR: could not copy Lua clib %%l & exit 6)
)

:: copy Lua libs
mkdir "%APP_DIR%\data\bin\lua"
for %%l in (%LUA_LIBS%) do (
  copy "%LUA_DIR%\lua\%%l.lua" "%APP_DIR%\data\bin\lua\"
  if errorlevel 1 (echo ERROR: could not copy Lua lib %%l & exit 7)
  :: additional folder?
  IF EXIST "%LUA_DIR%\lua\%%l" xcopy /s "%LUA_DIR%\lua\%%l" "%APP_DIR%\data\bin\lua\%%l\"
)

:: copy additional DLLs from Lua foldder into data folder
for %%l in (%LUA_DLLS%) do (
  copy "%LUA_DIR%\%%l" "%APP_DIR%\data\"
  if errorlevel 1 (echo ERROR: could not copy DLL %%l & exit 8)
)

:: go to outer standalone dir
cd "%APP_DIR%\.."

:: create a ZIP file?
if "%CREATE_ZIP%"=="1" (
  echo.
  echo Creating ZIP file...
  ::del "%APPNAME%.zip" 2>nul
  %ZIP_CMD% -q -r "%APPNAME%-win.zip" "%APPNAME%\*"
  if errorlevel 1 (echo ERROR: could not create ZIP file & exit 9)
)

echo Done.
