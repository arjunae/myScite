@echo off
SET RestoreFile=extRestore.reg

echo ..About to _restore_ the Filetypes backup  using %RestoreFile% ?
call choice /C YN /M "-- Continue?  Yes/No" 
if %ERRORLEVEL% == 2 goto ende

if not exist %RestoreFile% goto ende
regedit /S %RestoreFile%
echo ..Done..
goto ende

:FAIL_NF
echo extRestore.reg not found. Have you already create a backup? 

:ende
Pause