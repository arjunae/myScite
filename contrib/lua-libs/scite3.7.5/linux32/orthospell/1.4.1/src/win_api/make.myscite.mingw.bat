if exist *.o del *.o
mingw32-make -f makefile.myscite.mingw libparser.a
mingw32-make -f makefile.myscite.mingw libhunspell.a
if exist *.o del *.o

::strip libhunspell.a
::strip libparser.a

move *.a ..\..\..\