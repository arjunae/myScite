// build@ cmd /c gcc -Wall -shared -o msleep.dll -I./lua/5.1/include -L.\ -llua5.1 msleep.c
/*
 * http://www.troubleshooters.com/codecorn/lua/lua_lua_calls_c.htm#_Make_an_msleep_Function
*/

#include <unistd.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int msleep_c(lua_State *L){
	long msecs = lua_tointeger(L, -1);
	usleep(1000*msecs);
	return 0;                  /* No items returned */
}

// Can't name this sleep(), it conflicts with sleep() in unistd.h
static int sleep_c(lua_State *L){
	long secs = lua_tointeger(L, -1);
	sleep(secs);
	return 0;                  /* No items returned */
}

// Register both functions 
int luaopen_msleep(lua_State *L){
	lua_register( L, "msleep", msleep_c);  
	lua_register(L, "sleep", sleep_c);
	return 0;
}
