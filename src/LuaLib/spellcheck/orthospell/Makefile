INCLUDES= -I../lua/5.1/include -I../hunspell/1.4.1/src/win_api
LIBS=-L..\lua\ -llua5.1 -L..\hunspell -lparser -L..\hunspell -lhunspell 

CFLAGS = --std=gnu++11 $(INCLUDES) $(HUNSPELL_INC) libhunspell.def
LDFLAGS= -shared  -Wl, $(LIBS) -Wl,--enable-auto-image-base

T = lorthospell
LIBNAME	= $(T).dll

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	g++ $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)

#all:
#g++ -Wall -shared -o lhunspell.dll -I../lua/5.1/include -I../hunspell/1.4.1/src/win_api  -L..\hunspell -lhunspell -L..\hunspell -lparser  -L..\lua -llua5.1 lorthospell.cpp
