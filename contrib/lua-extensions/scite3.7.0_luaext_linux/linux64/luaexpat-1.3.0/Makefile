tLUA_INC= -I.
LUA_INC= -I../lua/5.1/include/
EXPAT_INC= -I../expat-2.1.0/

LIBA=libexpat/lib/ -lexpat
LIBB=../lib -lscite
LIBC=../lib/ -llua5.1

T = lxp
LIBNAME	= $(T).so

CXX =g++
CFLAGS =-g -pedantic -Wall -O2 -DPIC -ansi  $(LUA_INC) $(EXPAT_INC)
LDFLAGS= -s -shared -L$(LIBA) -L$(LIBB) -L$(LIBC) -static-libgcc -static-libstdc++ 

lxp_lib: src/$(LIBNAME)
src/$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  src/$(T)lib.c $(LDFLAGS)
