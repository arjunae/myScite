LUA_INC= -I./lua/5.1/include
HUNSPELL_INC= -I./hunspell/1.3/Include

LIBA=.\ libscite.a
LIBB=.\ libhunspell-1.3.dll.a
# LIBC=.\ liblua5.1.a

T = luahunspell
LIBNAME	= $(T).dll

CXX =g++
CFLAGS = -Wall -shared -lstdc++ $(LUA_INC) $(HUNSPELL_INC) 
LDFLAGS= -static -shared -Wl,--enable-auto-image-base -Wl, -L$(LIBA) -L$(LIBB) 
#-L$(LIBC)

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	$(CXX) $(CFLAGS)  -o $@  $(T).* $(LDFLAGS)
