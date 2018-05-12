::...::..:::...::..::.:.::
::	SciTE Clean	::
::...::..:::...::..::.:.::

@echo off

mode 130,18
pushd

cd scintilla
del /S /Q *.dll *.exe *.a *.aps *.bsc  *.dsw *.idb *.ilc *.ild *.ilf *.ilk *.ils *.lib *.map *.ncb *.obj *.o *.opt *.pdb *.plg *.res *.sbr *.tds *.exp *.pyc *.orig *.rej 2>NUL
cd ..
cd scite
del /S /Q *.dll *.exe *.a *.aps *.bsc  *.dsw *.idb *.ilc *.ild *.ilf *.ilk *.ils *.lib *.map *.ncb *.obj *.o *.opt *.pdb *.plg *.res *.sbr *.tds *.exp *.pyc *.orig *.rej 2>NUL

PAUSE
EXIT
