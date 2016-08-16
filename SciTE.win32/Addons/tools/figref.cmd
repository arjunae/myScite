@echo off 
:: -------- Starter for SciTE ----------
:: used to be able to avoid Chaos and store  Language Distbins within their respective Directories. 
:: ---------------------------------------

set toolName=figref

::~dp0 = Full Path to current Directory
set toolPath=%~dp0\%toolName%

:: temporarly append toolsDir to local Path 
set path=%path%;%toolPath%;

echo ~ WRapper: %toolName% %*
call %toolPath%\%toolName% -f %toolPath%\small.flf %*
::call %toolPath%\%toolName% -f %toolPath%\mini.flf %*

pause
