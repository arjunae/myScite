@echo off
::mode 112,20
REM  ::--::--::--::--Steampunk--::-::--::--::
REM
REM 
REM  ---- Wrapper for scite_filetypes.vbs uninstall ----
REM
REM :: Created April 1 , Marcedo@HabmalneFrage.de
REM :: License: BSD-3-Clause
REM :: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
REM :: Application Registering Reference: https://msdn.microsoft.com/en-us/library/windows/desktop/ee872121(v=vs.85).aspx
REM
REM -> todo vbs: Keep only those entries from the backup file, which we have initially modified.
REM 
REM ::--::--::--::--Steampunk--::-::--::--::

chcp 65001 1>NUL
set DataFile=scite_filetypes.txt

if not exist %dataFile% (
	echo  ......Please, first create %DataFile% with scite_filetypes.cmd install
	goto ende
)

echo.
echo  .. Parsing Filetypes in %DataFile% ..
cscript /NOLOGO scite_filetypes.vbs uninstall 
echo  .. done with clearing %ERRORLEVEL% Entries ..
echo.

:ende
pause
