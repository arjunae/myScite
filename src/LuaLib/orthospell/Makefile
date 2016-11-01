LUA_INC= -I./lua/5.1/include
HUNSPELL_INC= -I./Include

#LIBA=.\ libscite.a
LIBB=.\ libhunspell.dll.a
LIBC=.\ liblua5.1.a

T = luahunspell
LIBNAME	= $(T).dll

CXX =g++
CFLAGS =-g -pedantic -Wall -std=gnu++11  $(LUA_INC) $(HUNSPELL_INC)
LDFLAGS= -s -shared  -Wl, -L$(LIBA) -L$(LIBB) -L$(LIBC) -static

lxp_lib: $(LIBNAME)
$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)
