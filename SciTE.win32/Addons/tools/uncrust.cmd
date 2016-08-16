@echo off 
:: -------- Starter for SciTE ----------
:: used to be able to avoid Chaos and store  Language Distbins within their respective Directories. 
:: ---------------------------------------

set toolName=uncrustify

::~dp0 = Full Path to current Directory
set toolPath=%~dp0\%toolName%

:: temporarly append toolsDir to local Path 
set path=%path%;%toolPath%;

echo ~ WRapper: %toolName% %*
%toolPath%\%toolName%.exe -c %toolPath%\linux.cfg --no-backup  %*
::%toolPath%\%toolName%.exe -c %toolPath%\defaults.cfg --no-backup  %*
