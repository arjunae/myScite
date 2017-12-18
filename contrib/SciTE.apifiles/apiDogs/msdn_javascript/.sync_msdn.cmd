@echo off
if exist msdn.js.obj.raw del msdn.js.obj.raw
::echo.  > msdn.js.obj.raw

Start /B /MIN  cscript.exe //x  sync_msdn_js_obj.vbs
pause
