@echo off

::
:: 1) Export property "file.patterns" from all property files
:: 2) Keep only base entries (which dont use references) 
:: 3) Strip the filename prefixes which were added by FINDSTR
::

pushd %~dp0%
if exist scite_filetypes?.* del scite_filetypes?.*

:main

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
echo  .. Registering Filetypes ..
cscript /NOLOGO add_scite_filetypes.vbs
echo  .. parsed %ERRORLEVEL% Entries ..
echo.
popd
pause