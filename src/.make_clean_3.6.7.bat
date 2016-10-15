::...::..:::...::..::.:.::
::	SciTE Clean	::
::...::..:::...::..::.:.::

@echo off

:: ... use customized CMD Terminal
if "%1"=="" (
	reg import ...\contrib\TinyTonCMD\TinyTonCMD.reg
	start "TinyTonCMD" .make_clean_3.6.7.bat tiny
	EXIT
)
mode 130,18
cd 3.6.7
del /S /Q *.dll *.exe *.a *.aps *.bsc  *.dsw *.idb *.ilc *.ild *.ilf *.ilk *.ils *.lib *.map *.ncb *.obj *.o *.opt *.pdb *.plg *.res *.sbr *.tds *.exp *.pyc 2>NUL
PAUSE
EXIT
