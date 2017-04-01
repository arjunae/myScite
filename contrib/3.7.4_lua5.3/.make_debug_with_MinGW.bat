::...::..:::...::..::.:.::
::    SciTE Debug	::  
::...::..:::...::..::.:.::

@echo off
set PATH=E:\MinGW\bin;%PATH%;
set DEBUG=1
setlocal

mode 150,15
echo ::...::..:::...::..::.:.::
echo ::    SciTE Debug	::  
echo ::...::..:::...::..::.:.::

cd 3.7.4\scintilla\win32
mingw32-make
if errorlevel 1 goto :error

cd ..\..\scite\win32
mingw32-make
if errorlevel 1 goto :error
echo ------------------------------------------------
goto end

:error
pause

:end
cd ..\..
echo ------------------------------------------------
ECHO Waiting 33 seconds before closeing the window.
Ping 11.1.19.77 -n 1 -w 33333
EXIT
