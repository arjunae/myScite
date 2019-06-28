/* dbghelper
 *
 * Gunnar Zötl <gz@tset.de>, 2012
 * Released under the terms of the MIT License
 *
 * injects a function resumeuntil into the debug table, and also overwrites
 * coroutine.yield with a version that caters for our needs but still works
 * as expected.
 *
 * use:
 *	require "dbghelper"
 * 
 * cr = coroutine.create(function_to_debug)
 * ok, what = debug.resumeuntil(cr, mask, count, ...)
 *
 * Arguments:
 *	cr	coroutine to debug
 * 	mask, count are as for debug.sethook
 *	... extra arguments to pass to the coroutine resume function
 *		(only use if the coroutine has yielded or on the first call)
 *
 * Return values:
 *	ok	true if the coroutine can be resumed, false if not
 *	what event that caused resumeuntil to return, can be any one of
 *		- 'line', 'count', 'call', 'tail call', 'return', 'tail return' or
 *        'yield' if ok is true,
 *		- 'return' or 'error' if ok is false.
 *
 * - the mask and count arguments can be nil. If both are nil, resumeuntil
 *   will just resume the coroutine until it returns, yields or throws an
 *   error.
 * - if an error occurred, the error message is returned as the third return
 *   value from resumeuntil
 * - if ok and what are true and 'yield', the debugged function has yielded
 *   and arguments passed to yield are returned as third and following return
 *   values from resumeuntil
 * - if ok and what are false and 'return', the debugged function has returned
 *   and any return values are returned as third and following return values
 *   from resumeuntil
 * - if ok is true and what is anything but 'yield', this signals that the
 *   corresponding debug hook has been invoked.
 * - only lua 5.1 will return 'tail return', only lua 5.2 will return
 *   'tail call'.
 *
 * BEWARE: with this function you may be able to seriously foul up lua's
 * stack, so be careful.
 *
 * NOTES:
 * - you need access to lua's source tree, especially lstate.h, to compile
 *   this.
 */

#include <stdlib.h>
#include <stdio.h>

#include "lua.h"
#include "lauxlib.h"
#include "lstate.h"

#define REGIDX "*dbghelper*"

/* both lua 5.1 and 5.2 can only yield under certain circumstances. */
#if LUA_VERSION_NUM == 501
	#define LUA51
	#define YIELDCOND (L->nCcalls <= L->baseCcalls)
#elif LUA_VERSION_NUM == 503
	#define LUA52
	#define YIELDCOND (L->nny == 0)
#else
	#error "Lua version " LUA_VERSION " not supported"
#endif

/* Only from a count event can one sensibly yield from a debug hook. Yielding
 * from a call or return event will f*ck up the stack, and from a line event
 * will do no good because the hook is invoked before the line is executed, so
 * resuming the yielded function would continue at the same line start, throw
 * another line event... endless loop: see loop, endless.
 * But as count events are executed before the actual instruction is executed,
 * nothing is lost by yielding at the next count hook.
 * Line events are always reported when a new line is reached, so we only
 * report those of there is not already an event flagged.
 */
static void dbg_hook(lua_State *L, lua_Debug *ar)
{
	const char *evt = NULL;

	lua_getfield(L, LUA_REGISTRYINDEX, REGIDX);
	evt = lua_tostring(L, lua_gettop(L));
	lua_pop(L, 1);

	switch (ar->event) {
		case LUA_HOOKCALL: evt = "call"; break;
		case LUA_HOOKRET: evt = "return"; break;
		#ifdef LUA51
		case LUA_HOOKTAILRET: evt = "tail return"; break;
		#else
		case LUA_HOOKTAILCALL: evt = "tail call"; break;
		#endif
		case LUA_HOOKLINE: if (!evt) evt = "line"; break;
		case LUA_HOOKCOUNT:
			if (YIELDCOND) {
				lua_yield(L, 0);
				return;
			}
			/* reset last event if we can not yield here */
			evt = NULL;
		break;
		default: luaL_error(L, "unknown event");
	}

	lua_pushstring(L, evt);
	lua_setfield(L, LUA_REGISTRYINDEX, REGIDX);
}

/* we need coroutine.yield to signal that the user program has requested the
 * yield, not our hook
 */
static int dbg_luaB_yield (lua_State *L) {
	lua_pushstring(L, "yield");
	lua_setfield(L, LUA_REGISTRYINDEX, REGIDX);
	return lua_yield(L, lua_gettop(L));
}

/* lua function debug.resumeuntil
 *
 * resumes a coroutine until an event is encountered, which is specified like
 * the hook specification for debug.sethook()
 *
 * Lua Arguments:
 *	1	coroutine to run until the specified event happens
 *	2	event mask, any combination of c, r, l. See debug.sethook()
 *	3	instruction count. See debug.sethook()
 *  4+	(optional) arguments to resume the coroutine with
 *
 * Lua returns:
 *	1	true if the coroutine can be resumed, false otherwise
 *	2	the event that caused resumeuntil to return
 *	3+	in the case of an error, this is the error message
 *		if yielded or returned, here are the return values,
 *		nothing in all other cases
 */
static int dbg_resumeuntil(lua_State *L)
{
	const char *smask = luaL_optstring(L, 2, "");
	int count = luaL_optint(L, 3, 0);
	int status, i;
	int mask = 0;
	lua_Debug ar;
	char *name = NULL;
	int nargs = 0;
	int res = 2;

	luaL_checktype(L, 1, LUA_TTHREAD);
	lua_State *T = lua_tothread(L, 1);

	for (i = 0; smask[i]; ++i) {
		switch (smask[i]) {
			case 'l': mask |= LUA_MASKLINE; break;
			case 'c': mask |= LUA_MASKCALL; break;
			case 'r': mask |= LUA_MASKRET; break;
			default: return luaL_error(L, "unknown mask char: %c", smask[i]);
		}
	}
	if (count > 0) mask |= LUA_MASKCOUNT;

	const char *dbg_evt = NULL;
	lua_pushnil(T);
	lua_setfield(T, LUA_REGISTRYINDEX, REGIDX);

	/* arguments to resume */
	if (lua_gettop(L) > 3) {
		nargs = lua_gettop(L) - 3;
		lua_xmove(L, T, nargs);
	}

	/* Note: count is 2 because in the vm the count is decremented and checked
	 * _before_ the first instruction is carried out. So the actual number of
	 * instructions executed by the vm is count - 1. Here we decrement and
	 * check the count _after_ the instruction has been executed, so this
	 * function executes one instruction if the count is 1.
	 */
	lua_sethook(T, dbg_hook, LUA_MASKCOUNT | mask, 2);
	do {
		#ifdef LUA51
		status = lua_resume(T, nargs);
		#else
		status = lua_resume(T, L, nargs);
		#endif

		lua_getfield(T, LUA_REGISTRYINDEX, REGIDX);
		dbg_evt = lua_tostring(T, lua_gettop(T));
		lua_pop(T, 1);

		if (!dbg_evt && (mask & LUA_MASKCOUNT)) {
			--count;
			if (count <= 0)
				dbg_evt = "count";
		}
		nargs = 0;
	} while (status == LUA_YIELD && dbg_evt == NULL);
	lua_sethook(T, NULL, 0, 0);

	if (status == LUA_YIELD) {
		lua_pushboolean(L, 1);
		lua_pushstring(L, dbg_evt);
		/* fetch arguments to user yield */
		if (*dbg_evt == 'y') { /* if (!strcmp(dbg_evt, "yield")) { */
			res = 2 + lua_gettop(T);
			lua_xmove(T, L, lua_gettop(T));
		}
	} else if (status) {
		const char *err = lua_tostring(T, lua_gettop(T));
		lua_pushboolean(L, 0);
		lua_pushstring(L, "error");
		lua_pushstring(L, err);
		res = 3;
	} else {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "return");
		/* fetch return values */
		res = 2 + lua_gettop(T);
		lua_xmove(T, L, lua_gettop(T));
	}
	
	return res;
}

int luaopen_dbghelper(lua_State *L)
{
	/* replace coroutine.yield with our wrapper */
	lua_getglobal(L, "coroutine");
	lua_pushcfunction(L, dbg_luaB_yield);
	lua_setfield(L, -2, "yield");
	lua_pop(L, 1);
	
	/* inject our resumeuntil function into debug table */
	lua_getglobal(L, "debug");
	lua_pushcfunction(L, dbg_resumeuntil);
	lua_setfield(L, -2, "resumeuntil");
	lua_pop(L, 1);

	return 0;
}
