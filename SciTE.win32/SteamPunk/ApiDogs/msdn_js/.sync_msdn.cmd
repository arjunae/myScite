@echo off
if exist msdn.js.obj.raw del msdn.js.obj.raw
echo.  > msdn.js.obj.raw

Start /B /MIN  cscript.exe //D //Nologo  sync_msdn_js_obj.vbs
pause
