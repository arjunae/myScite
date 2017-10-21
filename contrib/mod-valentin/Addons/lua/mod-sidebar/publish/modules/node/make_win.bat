@echo off

:: Publish-Module for Node.js - Win version
:: (c) Valentin Schmidt 2016

:: config
set NODE_MOD_DIR=C:\node_modules

:: args
set APPNAME=%~1
set LIBS=%~2
set CREATE_ZIP=%~3
set APPROOT_FILES=%~4

:: start
set SRC=.
set STANDALONE_DIR=%cd%\..\%APPNAME%_standalone_win
set APP_DIR=%STANDALONE_DIR%\%APPNAME%
set ZIP_CMD="%~dp0..\..\bin\zip.exe"

::set RMDIR_CMD=rmdir /S /Q
set RMDIR_CMD="%~dp0..\..\bin\recycle.exe" -f

:: remove previous version if existing
IF EXIST "%APP_DIR%" %RMDIR_CMD% "%APP_DIR%" >nul 2>&1

:: make APP_DIR folder
mkdir "%APP_DIR%"
if errorlevel 1 (echo ERROR: could not create publish folder for project & exit 1)

:: copy app.exe
copy "%~dp0app.exe" "%APP_DIR%\%APPNAME%.exe"
if errorlevel 1 (echo ERROR: could not copy app.exe & exit 2)

:: make data folder
mkdir "%APP_DIR%\data"
if errorlevel 1 (echo ERROR: could not create data folder & exit 3)

:: copy folder
echo.
echo Copying project folder into data...
xcopy %SRC%\* "%APP_DIR%\data\" /s /exclude:%~dp0excludes+%~dp0excludes_win
if errorlevel 1 (echo ERROR: could not copy project folder & exit 4)

:: move AppRoot files to top folder
for %%f in (%APPROOT_FILES%) do (
  move "%APP_DIR%\data\%%f" "%APP_DIR%\"
  if errorlevel 1 (echo ERROR: could not move file %%f to app root folder & exit 5)
)

:: copy used node_modules
echo.
echo Copying node_modules...
mkdir "%APP_DIR%\data\node_modules"
for %%l in (%LIBS%) do (
  xcopy "%NODE_MOD_DIR%\%%l" "%APP_DIR%\data\node_modules\%%l\" /s /exclude:%~dp0excludes+%~dp0excludes_win
  if errorlevel 1 (echo ERROR: could not copy node_module %%l & exit 5)
)

:: copy node.exe
echo.
echo Copying node.exe...
mkdir "%APP_DIR%\data\bin"
copy "%~dp0node.exe" "%APP_DIR%\data\bin\"
if errorlevel 1 (echo ERROR: could not copy node.exe & exit 6)

:: go to outer standalone dir
cd "%APP_DIR%\.."

:: create a ZIP file?
if "%CREATE_ZIP%"=="1" (
  echo.
  echo Creating ZIP file...
  ::del "%APPNAME%.zip" 2>nul
  %ZIP_CMD% -q -r "%APPNAME%-win.zip" "%APPNAME%\*"
  if errorlevel 1 (echo ERROR: could not create ZIP file & exit 7)
)

echo Done.
