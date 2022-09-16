@echo off
REM	SciTE Clean
REM use customized CMD Terminal
if "%1"=="" (
REM  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
REM  start "TinyTonCMD" %~nx0 %1 tiny
REM  EXIT
)
mode 130,18
cd src
del /S /Q *.dll *.exe *.lib *.a *.aps *.bsc  *.dsw *.idb *.ilc *.ild *.ilf *.ilk *.ils *.map *.ncb *.obj *.o *.opt *.pdb *.plg *.res *.sbr *.tds *.exp *.pyc *.orig *.rej *.build 2>NUL
cd ..
echo.
echo OK
PAUSE
