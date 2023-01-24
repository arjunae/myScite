// build@ gcc -g -shared dbgl.c -o dbgl.so
// 24.01.2021 use luaL_setfuncs instead of luaL_openlib for >=LUA52 following https://github.com/TheLinx/lao/issues/2
// 25.01.2021 use size_t for len declaration
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "lstate.h"

static int debug_break (lua_State *L)
{
    return 0;
}

// unfortunately, I can't a method of extracting a pointer to the C function 
// called immediately before this function, that doesn't use Lua internal stuff.
static int c_addr (lua_State *L)
{
    char buff[40];
    CallInfo *ci;
    Closure* cl = NULL;
#if defined LUA_VERSION_NUM && LUA_VERSION_NUM <503    
    for (ci = L->ci - 1; ci > L->base_ci; ci--) {
      if (! f_isLua(ci)) {  // C function!
#else
    for (ci = L->ci; ci != NULL; ci = ci->previous) {
      if (! isLua(ci)) {  // C function!
#endif
        cl = clvalue(ci->func);	
      	break;
      }
    }
    if (cl == NULL) {
      lua_pushnil(L);
    } else {
      void *fun = cl->c.f;    
      sprintf(buff,"0x%X",fun);
      lua_pushstring(L,buff);
    }
    return 1;
}

// this is indended to be called from GDB as a debug convenience function
void debug_lua_stack(lua_State *L)
{
    int nstack = lua_gettop(L);
    int idx,ltype;
    size_t len;
    const char* str;
    printf("nstack = %d\n",nstack);
    for (idx = 1; idx <= nstack; idx++) {
        ltype = lua_type(L,idx);
        printf("%d ",idx);
        switch(ltype) {
        case LUA_TNIL:
            printf("<nil>\n"); 
            break;
        case LUA_TNUMBER:
            printf("%f\n",lua_tonumber(L,idx));
            break;
        case LUA_TSTRING:
            str = lua_tolstring(L,idx,&len);
            printf("'%s' [%d]\n",str,len);
            break;
        case LUA_TTABLE:
            printf("table %X\n",lua_topointer(L,idx));
            break;            
        case LUA_TFUNCTION:
            printf("function %X\n",lua_topointer(L,idx));
            break;
        case LUA_TBOOLEAN:
            printf("%s\n",lua_toboolean(L,idx) ? "true" : "false");
            break;
        case LUA_TUSERDATA:
            printf("user %X\n",lua_touserdata(L,idx));
            break;
        case LUA_TLIGHTUSERDATA:
            printf("light user %X\n",lua_touserdata(L,idx));
            break;                        
        case LUA_TTHREAD:
            printf("thread %X\n",lua_tothread(L,idx));
            break;
        }      
    }
}

static const struct luaL_Reg dbgl[] = {
	{"debug_break", debug_break},
	{"c_addr",c_addr},
	{NULL, NULL},
};

int luaopen_dbgl (lua_State *L) {
#if LUA_VERSION_NUM >= 502
    lua_newtable(L);
    luaL_setfuncs(L, dbgl, 0);
    lua_pushvalue(L, -1);
    lua_setglobal(L, "dbgl");
#else
	luaL_openlib (L, "dbgl", dbgl, 0);
#endif
	return 1;
}
