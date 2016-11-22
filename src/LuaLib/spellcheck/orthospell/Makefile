
# -- Normally linked with scites internal lua interpreter. (independency to lua5.1.dll)  
LUA=-L.\ -lscite

# -- If you plan to use orthospell without scite, link with lua5.1
#LUA=-L..\lua\ -llua5.1

# -- Avoid runtime errors. statically link stdc, even when scite might be too.
INCLUDES= -I../lua/5.1/include -I../hunspell/1.4.1/src/win_api libhunspell.def
LIBS=-L..\hunspell -lparser -L..\hunspell -lhunspell $(LUA)  -static-libgcc -static-libstdc++

#-- make sure that lua symbols can be seen: -DLUA_API=__declspec(dllimport)  
CFLAGS = -o2  -DLUA_API=__declspec(dllimport) 
LDFLAGS= -s -shared -Wl, $(LIBS) -Wl,--dll

T = hunspell
LIBNAME	= $(T).dll

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	g++ hunspell.cpp $(CFLAGS) -o hunspell.dll  $(INCLUDES) $(LDFLAGS)
