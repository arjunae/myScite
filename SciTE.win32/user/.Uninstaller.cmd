@echo off
::mode 112,20
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
