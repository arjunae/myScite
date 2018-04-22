@echo off
REM Choose to enable WorkArounds for Reactos 0.4.8. Valid Values: 0/1 
::set FIX_REACTOS=1
cd installer
.installer %FIX_REACTOS%