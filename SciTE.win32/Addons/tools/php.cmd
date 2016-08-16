@echo off
:: -------- Starter for SciTE ----------
:: used to be able to avoid Chaos and store  Language Distbins within their respective Directories. 
:: ---------------------------------------
set toolName=php

::~dp0 = Full Path to current Directory
set toolPath=%~dp0\%toolName%

:: temporarly append toolsDir to local Path 
set path=%path%;%toolPath%;

echo ~ WRapper: %toolName% %*
%toolpath%\%toolName%.exe %*
