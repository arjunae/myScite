@echo off

pushd %~dp0%
del *.raw? *.txt

:main
REM 1) Export property "file.patterns" from all property files
FINDSTR /SI "^file.patterns." *.properties > filetypes.raw1

REM 2) Keep only base entries (which dont use references) 
FINDSTR /SIV "$(" filetypes.raw1 >filetypes.raw2

REM 2) Strip the filename prefixes which were added by FINDSTR
for /F "delims=: eol=# tokens=3" %%E in (filetypes.raw2) do (
 echo %%E>>filetypes.v150.txt
) 

del *.raw?