@echo off

::
:: 1) Export property "file.patterns" from all property files
:: 2) Keep only base entries (which dont use references) 
:: 3) Strip the filename prefixes which were added by FINDSTR
::

pushd %~dp0%
if exist scite_filetypes?.* del scite_filetypes?.*

if ["%1"] equ ["/quite"] goto main
echo  ..About to soft-register Filetypes with mySciTE
call choice /C YN /M " Continue?  Yes/No" 
if %ERRORLEVEL% == 2 goto ende

:main
echo  ..Creating scite_filetypes.txt
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
echo  .. Parsing Filetypes ..
cscript /NOLOGO add_scite_filetypes.vbs
echo  .. done with %ERRORLEVEL% Entries ..
echo.
popd

:ende
pause
