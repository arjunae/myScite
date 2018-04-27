::...::..:::...::..::.:.::
::    SciTE Prod   ::  
::...::..:::...::..::.:.::

@echo off
::set PATH=D:\apps\i686-7.1.0-win32-dwarf-rt_v5-rev0\mingw32\bin;%PATH%;
setlocal enabledelayedexpansion enableextensions

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ...\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" .make_release_with_MinGW.bat tiny
  EXIT
)

echo ::..::..:::..::..::.:.::
echo ::    SciTE Prod      ::
echo ::..::..:::..::..::.:.::

del Release\SciTE.exe 2>NUL
del Release\SciLexer.dll 2>NUL

cd scintilla\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error

cd ..\..\scite\win32
mingw32-make -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 goto :error

echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

REM This littl hack looks for a platform PE Signature at offset 120+
REM Should work compiler independent for uncompressed binaries.
REM Offsets MSVC/MINGW==120 BORLAND==131 PaCKERS >xxx
REM -1 suggests that a binary is compressed

set PLAT=""
set file=..\bin\SciTE.exe

for /f "delims=:" %%A in ('findstr /o "^.*PE..L." "%file%"') do ( 
  if %%A LEQ 200 (SET PLAT=WIN32) ELSE (SET PLAT=NIL) 
  if %%A LEQ 200 (SET OFFSET=%%A) ELSE (SET OFFSET=-1)
)

for /f "delims=:" %%B in ('findstr /o "^.*PE..d." "%file%"') do (
  if %%B LEQ 200 (SET PLAT=WIN64) ELSE (SET PLAT=NIL)
  if %%B LEQ 200 (SET OFFSET=%%B) ELSE (SET OFFSET=-1)
)

echo .... Targets platform [%PLAT%] ......
If [%PLAT%]==[WIN32] (
move ..\bin\SciTE.exe ..\..\release
move ..\bin\SciLexer.dll ..\..\release
)

If [%PLAT%]==[WIN64] (
move ..\bin\SciTE.exe ..\..\release
move ..\bin\SciLexer.dll ..\..\release
)

goto end

:error
pause

:end
cd ..\..
PAUSE
EXIT
