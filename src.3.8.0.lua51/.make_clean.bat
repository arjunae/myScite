::...::..:::...::..::.:.::
::	SciTE Clean	::
::...::..:::...::..::.:.::

@echo off

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" %~nx0 %1 tiny
  EXIT
)
mode 130,18
cd src
del /S /Q *.dll *.exe *.lib *.a *.aps *.bsc  *.dsw *.idb *.ilc *.ild *.ilf *.ilk *.ils *.map *.ncb *.obj *.o *.opt *.pdb *.plg *.res *.sbr *.tds *.exp *.pyc *.orig *.rej *.build 2>NUL
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
PAUSE
EXIT
