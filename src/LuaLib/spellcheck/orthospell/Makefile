INCLUDES= -I../lua/5.1/include -I../hunspell/1.4.1/src/win_api libhunspell.def
LIBS=-L..\hunspell -lparser -L..\hunspell -lhunspell  -L..\lua\ -llua5.1
#-L.\ -lscite
CFLAGS = -o2
LDFLAGS= -shared -Wl, $(LIBS) -Wl,-e,_DllMain@12 -Wl,--dll

T = hunspell
LIBNAME	= $(T).dll

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	g++ hunspell.cpp $(CFLAGS) -o hunspell.dll  $(INCLUDES) -s -shared -static-libgcc -static-libstdc++  $(LDFLAGS)
	

#hunspell_lib: $(LIBNAME)
#$(LIBNAME):	
#g++ $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)
	
