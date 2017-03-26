@echo off

pushd %~dp0%
if exist %tmp%\*.raw? del %tmp%\*.raw?
REM toDo: make shellscript position aware
cd ..

:main
REM 1) Export property "file.patterns" from all property files
FINDSTR /SI "^file.patterns." *.properties > filetypes1.raw

REM 2) Keep only base entries (which dont use references) 
FINDSTR /SIV "$(" filetypes1.raw > filetypes2.raw

REM 2) Strip the filename prefixes which were added by FINDSTR
for /F "delims=: eol=# tokens=3" %%E in (filetypes2.raw) do (
 echo %%E>>filetypes.v150.txt
) 

del *.raw?
popd