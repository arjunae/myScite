@echo off
mode 112,20
REM ---------------- Test Batch -----------------
REM List and Identify Binaries Platform (w32/w64)
REM ---------------------------------in--------------

echo ... Display executables Platform, starting from current Directory...
echo  ... Click outputPane and press Key.
pause >NUL
call :sub_lister
pause
exit /b 0

:sub_lister
:: List all Files, begin from current DIR
:: Press F5 to test.

setlocal EnableDelayedExpansion
ECHO Searching for PE Header in files...

FOR /R %%I IN (*.dll) DO ( 
set file=%%I
call :sub_platform
)


FOR /R %%I IN (*.EXE) DO ( 
set file=%%I
call :sub_platform
)

::runas /noprofile /user:Tho cmd
exit /b 0
:end_sub 

:sub_platform
SET PLAT=NIL
SET OFFSET=0

REM Offsets MSVC/MINGW==120 BORLAND==131 PaCKERS >xxx
for /f "delims=:" %%A in ('findstr /o "^.*PE..L." "%file%"') do ( 
if %%A LEQ 250 (SET PLAT=win32) ELSE (SET PLAT=NIL) 
if %%A LEQ 250 (SET OFFSET=%%A) ELSE (SET OFFSET=-1)
)

for /f "delims=:" %%B in ('findstr /o "^.*PE..d." "%file%"') do (
if %%B LEQ 250 (SET PLAT=win64) ELSE (SET PLAT=NIL)
if %%B LEQ 250 (SET OFFSET=%%B) ELSE (SET OFFSET=-1)
)

IF PLAT NEQ NIL echo -- [ %PLAT% ] [ %OFFSET% ] %FILE%

exit /b 0
:end_sub

:freude
:: wait some time...
ping 1.0.3.0 /n 1 /w 2000 >NUL
