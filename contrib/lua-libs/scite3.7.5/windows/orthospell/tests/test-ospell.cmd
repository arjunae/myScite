@ECHO OFF
SET PATH=H:\MinGW\bin;%ProgramFiles%\CodeBlocks\bin;%PATH%

:: test build
ECHO ---------- test lua_orthospell
if exist hunspell.dll cmd /U /c  lua test-ospell.lua
pause
