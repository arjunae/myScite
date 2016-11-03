
#include "hunspell.hxx"
#include <stdio.h>
#include <windows.h>

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT 
#endif

#include <lua.hpp>
/*
extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

*/
Hunspell* pMS = NULL;

// lua: hunspell.init(<affix file path>, <dict file path>)

static int l_init(lua_State *L)
{  
  
  if(pMS) delete pMS;
  pMS = new Hunspell("","");

  //printf("%s",lua_tostring(L, 1));
 printf("called linit");  
 return 0;  // number of results
}

static const struct luaL_reg luafns[] =
{
  {"init", l_init}, 
  {NULL, NULL}
};

extern "C" DLLEXPORT int luaopen_hunspell(lua_State *L)
{
  
  luaL_register(L, "hunspell", luafns); // failes calling lua function ?!
  printf("- called luaopen_hunspell\n");
  return 0;
}

/* Lua version. */

extern "C" DLLEXPORT const char* lua_version(void)
{
  printf("- called lua_version\n");
	return "1.5.2";
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
  printf("- load/unload hunspell\n");
  return TRUE;
}
