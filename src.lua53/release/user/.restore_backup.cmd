@echo off
SET RestoreFile=extRestore.reg

echo ..About to _restore_ the Filetypes backup  using %RestoreFile% ?
call choice /C YN /M "-- Continue?  Yes/No" 
if %ERRORLEVEL% == 2 goto ende

if not exist %RestoreFile% goto ende
REM Since we write to HKCU  the only reason for requiring admin privs
REM  would be because of changes to "UserChoice" subkeys.
REM Since we have no rason to do so, we can safely ignore admin priv related errors.
REM -> todo Keep only those entries from the backup file, which we have initially modified.
REM -> todo use reg.exe
REM -> Remove WhiteSpace
regedit /S %RestoreFile%
echo ..Done..
goto ende

:FAIL_NF
echo extRestore.reg not found. Have you already create a backup? 

:ende
Pause