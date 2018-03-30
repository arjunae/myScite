@echo off
chcp 65001 1>NUL
::  ---- Wrapper for scite_filetypes.vbs ----
::
:: 1) Export property "file.patterns" from all property files
:: 2) Keep only base entries (which dont use references) 
:: 3) Strip the filename prefixes which were added by FINDSTR
:: 4) Call scite_filetypes.vbs install
::
:: Mar2018 - Marcedo@habMalNeFrage.de
:: License: BSD-3-Clause
::
:: todo: Backup HKCU...\Explorer\FileExts
::

set DataFile=scite_filetypes.txt

pushd %~dp0%
if exist scite_filetypes?.txt del scite_filetypes?.txt

if ["%1"] equ ["/quite"] goto main
echo   ..About to soft-register Filetypes with mySciTE
call choice /C YN /M " Continue?  Yes/No" 
if %ERRORLEVEL% == 2 goto ende

:main
echo  .. Creating %DataFile%
:: collect file.patterns from all properties, ( prefixed with properties filname)
FINDSTR /SI "^file.patterns." *.properties > filetypes1.raw

:: Now filter unusable dupe entries (variable references) from above tmpfile. 
FINDSTR /SIV "$(" filetypes1.raw > filetypes2.raw

:: Finally, strip the file names, but keep the fileexts information. 
for /F "delims=: eol=# tokens=3" %%E in (filetypes2.raw) do (
 echo %%E>>scite_filetypes.txt
 if ["%1"] neq ["/quite"] echo %%E
) 

del *.raw?
echo.
echo  .. Parsing Filetypes in %DataFile% ..
cscript /NOLOGO scite_filetypes.vbs install
echo  .. done with %ERRORLEVEL% Entries ..
echo.
popd

:ende
