LUA_INC= -I./lua/5.1/include
HUNSPELL_INC= -I./hunspell/1.3/Include

#LIBA=.\ libscite.a
LIBA=.\lua\ -llua5.1
LIBB=.\hunspell\ -lparsers.dll
LIBC=.\hunspell\ -lhunspell.dll

T = luahunspell
LIBNAME	= $(T).dll

CXX =g++
CFLAGS = --std=gnu++11 $(LUA_INC) $(HUNSPELL_INC) 
LDFLAGS= -shared  -Wl, -L$(LIBA) -L$(LIBB) -L$(LIBC)
#-Wl,--enable-auto-image-base

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)
