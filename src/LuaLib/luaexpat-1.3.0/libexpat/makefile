LUA_INC= -I..\lualib\lua\5.1\include
EXPAT_INC= -I.

LUA_LIB=-l..\lib\lscite
LIBA= -l..\lib\lua5.1.dll

T = lxp
LIBNAME	= $(T).dll

# Compile Phase
CXX =g++
CFLAGS =-g -pedantic -Wall -O2 -DPIC -ansi  $(LUA_INC) $(EXPAT_INC) 
LDFLAGS= -s -shared -Wl,--enable-stdcall-fixup -Wl,--export-all-symbols  -Wl, -L$(LUA_LIB)  -static-libgcc -static-libstdc++

# Linker Phase

lxp_lib: $(LIBNAME)
$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@ *.c $(LDFLAGS)
