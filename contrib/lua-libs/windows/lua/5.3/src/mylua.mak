INSTALL_ROOT=   C:\Lua53

BINDIR=         $(INSTALL_ROOT)\bin
INCLUDEDIR=     $(INSTALL_ROOT)\include
LIBDIR=         $(INSTALL_ROOT)\lib

LUA_NAME=       lua.exe
LUA_LIB_NAME=   lua.lib

LUAC_NAME=      luac.exe

SOURCE_ROOT=    $(MAKEDIR)

CFLAGS=/O2 /TC /MT /DLUA_COMPAT_5_1 /DWIN32 /D_WINDOWS /D_MBCS \
/GS $(WARN) $(RUNTIME) $(OPTIM) 

LUA_LIB_DEPS=lapi.obj lcode.obj lctype.obj ldebug.obj ldo.obj ldump.obj \
    lfunc.obj lgc.obj llex.obj lmem.obj lobject.obj lopcodes.obj \
    lparser.obj lstate.obj lstring.obj ltable.obj ltm.obj lundump.obj \
    lvm.obj lzio.obj lauxlib.obj lbaselib.obj lbitlib.obj lcorolib.obj ldblib.obj \
    liolib.obj lmathlib.obj loslib.obj lstrlib.obj ltablib.obj \
    lutf8lib.obj loadlib.obj linit.obj

LUA_DEPS=lua.obj 

LUAC_DEPS=luac.obj

ALL_DEPS=$(LUA_LIB_DEPS) $(LUA_DEPS) $(LUAC_DEPS)

TO_BIN=$(LUA_NAME) $(LUAC_NAME)
TO_INCLUDE=lua.h luaconf.h lualib.h lauxlib.h lua.hpp
TO_LIB=$(LUA_LIB_NAME)

all: $(LUA_LIB_NAME)  $(LUA_NAME) 

cleanobj:
    @echo Cleaning object files...
    @del /F $(LUA_DEPS) $(LUAC_DEPS) $(LUA_LIB_DEPS)

clean: cleanobj
    @echo Cleaning binaries and libraries...
    @del /F $(LUA_NAME) $(LUAC_NAME) $(LUA_LIB_NAME)

install: all
    @echo Creating destination directory for binaries...
    @mkdir "$(BINDIR)"
    @echo Copying binaries...
    @for %%G in ($(TO_BIN)) do copy /Y "%%G" "$(BINDIR)\%%G"
    @echo Creating destination directory for headers...
    @mkdir "$(INCLUDEDIR)"
    @echo Copying headers...
    @for %%G in ($(TO_INCLUDE)) do copy /Y "$(SOURCE_ROOT)\%%G" "$(INCLUDEDIR)\%%G"
    @echo Creating destination directory for libraries...
    @mkdir "$(LIBDIR)"
    @echo Copying libraries...
    @for %%G in ($(TO_LIB)) do copy /Y "%%G" "$(LIBDIR)\%%G"

$(LUA_LIB_NAME): $(LUA_LIB_DEPS)
    lib.exe /OUT:$(LUA_LIB_NAME) $(LUA_LIB_DEPS)

$(LUA_NAME): $(LUA_DEPS) $(LUA_LIB_DEPS) 
    link.exe /OUT:$(LUA_NAME) $(LUA_DEPS) $(LUA_LIB_DEPS) ..\..\..\clib\scite_lua5.3\scite.lib

$(LUAC_NAME): $(LUAC_DEPS) $(LUA_LIB_DEPS)
    link.exe /OUT:$(LUAC_NAME) $(LUAC_DEPS) $(LUA_LIB_DEPS)
    
lapi.obj: {$(SOURCE_ROOT)}lapi.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lapi.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lundump.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lauxlib.obj: {$(SOURCE_ROOT)}lauxlib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lbaselib.obj: {$(SOURCE_ROOT)}lbaselib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lbitlib.obj: {$(SOURCE_ROOT)}lbitlib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lcode.obj: {$(SOURCE_ROOT)}lcode.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lcode.h \
    {$(SOURCE_ROOT)}llex.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}lopcodes.h \
    {$(SOURCE_ROOT)}lparser.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lcorolib.obj: {$(SOURCE_ROOT)}lcorolib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lctype.obj: {$(SOURCE_ROOT)}lctype.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lctype.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}llimits.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ldblib.obj: {$(SOURCE_ROOT)}ldblib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ldebug.obj: {$(SOURCE_ROOT)}ldebug.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lapi.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}lcode.h \
    {$(SOURCE_ROOT)}llex.h \
    {$(SOURCE_ROOT)}lopcodes.h \
    {$(SOURCE_ROOT)}lparser.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ldo.obj: {$(SOURCE_ROOT)}ldo.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lapi.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lopcodes.h \
    {$(SOURCE_ROOT)}lparser.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lundump.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ldump.obj: {$(SOURCE_ROOT)}ldump.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}lundump.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lfunc.obj: {$(SOURCE_ROOT)}lfunc.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lgc.obj: {$(SOURCE_ROOT)}lgc.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
linit.obj: {$(SOURCE_ROOT)}linit.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lualib.h \
    {$(SOURCE_ROOT)}lauxlib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
liolib.obj: {$(SOURCE_ROOT)}liolib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
llex.obj: {$(SOURCE_ROOT)}llex.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lctype.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}llex.h \
    {$(SOURCE_ROOT)}lparser.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lmathlib.obj: {$(SOURCE_ROOT)}lmathlib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lmem.obj: {$(SOURCE_ROOT)}lmem.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lgc.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
loadlib.obj: {$(SOURCE_ROOT)}loadlib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lobject.obj: {$(SOURCE_ROOT)}lobject.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lctype.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lopcodes.obj: {$(SOURCE_ROOT)}lopcodes.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lopcodes.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
loslib.obj: {$(SOURCE_ROOT)}loslib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lparser.obj: {$(SOURCE_ROOT)}lparser.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lcode.h \
    {$(SOURCE_ROOT)}llex.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}lopcodes.h \
    {$(SOURCE_ROOT)}lparser.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}ltable.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lstate.obj: {$(SOURCE_ROOT)}lstate.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lapi.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}llex.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lstring.obj: {$(SOURCE_ROOT)}lstring.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}lgc.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lstrlib.obj: {$(SOURCE_ROOT)}lstrlib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ltable.obj: {$(SOURCE_ROOT)}ltable.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ltablib.obj: {$(SOURCE_ROOT)}ltablib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
ltm.obj: {$(SOURCE_ROOT)}ltm.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lua.obj: {$(SOURCE_ROOT)}lua.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
luac.obj: {$(SOURCE_ROOT)}luac.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}lundump.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lopcodes.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lundump.obj: {$(SOURCE_ROOT)}lundump.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lundump.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lutf8lib.obj: {$(SOURCE_ROOT)}lutf8lib.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}lauxlib.h \
    {$(SOURCE_ROOT)}lualib.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lvm.obj: {$(SOURCE_ROOT)}lvm.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}ldebug.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}ldo.h \
    {$(SOURCE_ROOT)}lfunc.h \
    {$(SOURCE_ROOT)}lgc.h \
    {$(SOURCE_ROOT)}lopcodes.h \
    {$(SOURCE_ROOT)}lstring.h \
    {$(SOURCE_ROOT)}ltable.h \
    {$(SOURCE_ROOT)}lvm.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
    
lzio.obj: {$(SOURCE_ROOT)}lzio.c \
    {$(SOURCE_ROOT)}lprefix.h \
    {$(SOURCE_ROOT)}lua.h \
    {$(SOURCE_ROOT)}luaconf.h \
    {$(SOURCE_ROOT)}llimits.h \
    {$(SOURCE_ROOT)}lmem.h \
    {$(SOURCE_ROOT)}lstate.h \
    {$(SOURCE_ROOT)}lobject.h \
    {$(SOURCE_ROOT)}ltm.h \
    {$(SOURCE_ROOT)}lzio.h
    @cd "$(SOURCE_ROOT)"
    cl.exe /c $(CFLAGS) /Fo"$(MAKEDIR)\$*.obj" $*.c
    @cd "$(MAKEDIR)"
