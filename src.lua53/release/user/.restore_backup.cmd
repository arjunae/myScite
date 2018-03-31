@echo off
SET RestoreFile=extRestore.reg

REM .......................
REM Since we write to HKCU  the only reason for requiring admin privs
REM  would be because of changes to "UserChoice" subkeys.
REM Since we have no rason to do so, we can safely ignore admin priv related errors.
REM -> todo vbs: Keep only those entries from the backup file, which we have initially modified.
REM -> todo use reg.exe
REM ........................

echo ..About to _restore_ the Filetypes backup  using %RestoreFile% ?
call choice /C YN /M "-- Continue?  Yes/No" 
if %ERRORLEVEL% == 2 goto ENDE
if not exist %RestoreFile% goto FAIL_NF

:: Modern Regedits refuse to import files, when they are not located withi %tmp%
move %RestoreFile% %tmp%
regedit  /s %tmp%\%RestoreFile%
del /F /Q %tmp%\%RestoreFile%
echo ..Done..
goto ende

:FAIL_NF
echo  ~~ extRestore.reg not found. Did you already create a backup? 

:ENDE
Pause