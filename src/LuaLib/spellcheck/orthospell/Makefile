LUA_INC= -I../lua/5.1/include
#HUNSPELL_INC= -I../hunspell/1.3/Include
HUNSPELL_INC= -I../hunspell/1.4.1/src/win_api

#LIBA=.\ libscite.a
LIBA=..\lua\ -llua5.1
#LIBB=.\hunspell\ -lparsers.dll
#LIBC=.\hunspell\ -lhunspell.dll

LIBB=..\hunspell -lparser
LIBC=..\hunspell -lhunspell

T = lorthospell
LIBNAME	= $(T).dll

CXX =g++
CFLAGS = --std=gnu++11 $(LUA_INC) $(HUNSPELL_INC) libhunspell.def
LDFLAGS= -shared  -Wl, -L$(LIBA) -L$(LIBB) -L$(LIBC)
#-Wl,--enable-auto-image-base

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)
