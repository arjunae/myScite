LUA_INC= -I../lua/5.1/include -I../hunspell/1.4.1/src/win_api

#LIBA=.\ -lscite
LIBA=.\ -llua5.1
LIBB=..\hunspell -lparser
LIBC=..\hunspell -lhunspell

T = lhunspell
LIBNAME	= $(T).dll

CXX =g++
CFLAGS = -g -O2 --std=gnu++11 $(LUA_INC)  libhunspell.def
LDFLAGS= -static -shared  -Wl,-L$(LIBB) -L$(LIBC)  -L$(LIBA) 
#-Wl,--enable-auto-image-base

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)
