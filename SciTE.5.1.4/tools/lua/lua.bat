@echo off
set myLuaHome=%~dp0%
set path=%~dp0..\..\;%PATH%
lua.exe -l startup %*