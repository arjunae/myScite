@ECHO OFF
SET PATH=H:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

:: test build
ECHO ---------- test lua_hunspell
cmd /c lua test-hspell.lua
pause
