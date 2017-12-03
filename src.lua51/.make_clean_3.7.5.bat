::...::..:::...::..::.:.::
::	SciTE Clean	::
::...::..:::...::..::.:.::

@echo off

:: ... use customized CMD Terminal
if "%1"=="" (
	reg import ...\contrib\TinyTonCMD\TinyTonCMD.reg
	start "TinyTonCMD" .make_clean_3.7.5.bat tiny
	EXIT
)
mode 130,18
::cd 3.7.5/SCite 
del /S /Q *.dll *.exe  *.aps *.bsc  *.dsw *.idb *.ilc *.ild *.ilf *.ilk *.ils *.lib *.map *.ncb *.obj *.o *.opt *.pdb *.plg *.res *.sbr *.tds *.exp *.pyc *.orig *.rej 2>NUL
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------
PAUSE
EXIT
