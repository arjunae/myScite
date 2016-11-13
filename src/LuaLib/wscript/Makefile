
# -- Normally linked with scites internal lua interpreter. (independency to lua5.1.dll)  
LUA=-L.\ -lscite

# -- If you plan to use orthospell without scite, link with lua5.1
#  -L..\lua\ -llua5.1

# -- Avoid runtime errors. statically link stdc, even when scite might be too.
INCLUDES= -I./include/
LIBS= -static-libgcc -static-libstdc++

#-- make sure that lua symbols can be seen: -DLUA_API=__declspec(dllimport)  
CFLAGS = -std=c99 -D _WIN32_IE=0x0500 -D WINVER=0x500 
LDFLAGS=-s -luuid -lshell32 -loleaut32 -lole32 -luser32 -ladvapi32 -Wl,--subsystem,windows $(LIBS) 

T = hunspell
LIBNAME	= $(T).dll

hunspell_lib: $(LIBNAME)
$(LIBNAME):
	gcc *.c $(CFLAGS) -o w.exe $(INCLUDES)  -s -static $(LDFLAGS)
