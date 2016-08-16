tLUA_INC= -I.
LUA_INC= -I../lua/5.1/include/
EXPAT_INC= -I../expat-2.1.0/

LIBA=libexpat\lib\ -lexpat
LIBB=..\lib -lscite
LIBC=..\lib\ -llua5.1

T = lxp
LIBNAME	= $(T).dll

CXX =g++
CFLAGS =-g -pedantic -Wall -O2 -DPIC -ansi  $(LUA_INC) $(EXPAT_INC)  lxp.def
LDFLAGS= -s -shared  -Wl, -L$(LIBA) -L$(LIBB) -L$(LIBC) -static-libgcc -static-libstdc++ 

lxp_lib: src/$(LIBNAME)
src/$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  src/$(T)lib.c $(LDFLAGS)
