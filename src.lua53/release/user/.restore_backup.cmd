@echo off
SET RestoreFile=extRestore.reg

REM  ::--::--::--::--Steampunk--::-::--::--::
REM
REM  Apply a pre-generated fileExt Restore file  (for win7+)
REM
REM :: Created April 1 , Marcedo@HabmalneFrage.de
REM :: License: BSD-3-Clause
REM :: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
REM :: Application Registering Reference: https://msdn.microsoft.com/en-us/library/windows/desktop/ee872121(v=vs.85).aspx
REM
REM -> todo vbs: Keep only those entries from the backup file, which we have initially modified.
REM 
REM ::--::--::--::--Steampunk--::-::--::--::

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