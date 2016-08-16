@ECHO OFF
SET root=%~dp0
if not exist _clib_bin mkdir _clib_bin

rem -----------------------------------------------------
CALL :header Make SHELL.DLL
CD %root%\shell
CALL make.cmd
MOVE /Y shell.dll ..\_clib_bin

rem -----------------------------------------------------
CALL :header Make GUI.DLL
CD %root%\gui
CALL make.cmd
MOVE /Y gui.dll ..\_clib_bin

rem -----------------------------------------------------
CALL :header Make LPEG.DLL
CD %root%\lpeg
CALL make.cmd

rem -----------------------------------------------------
CALL :header Make lua_socket
CD %root%\luasocket-3.0-rc1

if not exist ..\_clib_bin\mime mkdir ..\_clib_bin\mime
if not exist ..\_clib_bin\socket mkdir ..\_clib_bin\socket

call make.bat

rem -----------------------------------------------------
CALL :header Make lua_expat

CD %root%\luaexpat-1.3.0
call make.cmd
rem -----------------------------------------------------
CALL :header Make spawner-ex

CD %root%\spawner-ex
if not exist ..\_clib_bin\scite-debug mkdir ..\_clib_bin\scite-debug
CALL make.bat
rem -----------------------------------------------------


GOTO end

:header
ECHO.
ECHO ^> ~~~~~~ [ %* ] ~~~~~~
TITLE Create SciTE: %*
GOTO :EOF

:end
CD %root%
