-
-- Interface
 Scite provides a nice API to Lua scripts:

 - globals -
 editor - the editor pane.
 output - the output pane.
 props - a pseudo-table representing the SciTE properties.
 buffer - a table associated with the current buffer or document.
 scite - a namespace for functions which control SciTE.
 trace(str) - writes s to the output pane (no prefix, no newlines).
 dostring(str) - executes as as a Lua string, like early Lua's dostring.

 :-> included lua.scite.api to show some nice calltips.

-- Remdebugging
 You can use SciTE not only to debug the executable, but any SciTE Lua scripts.
 Put these statements into the debuggee. The first one ensures that SciTE can find other Lua packages using require;
 Alternatively you can put a copy of engine.lua in a directory remdebug in your SciTE package.path

 require "remdebug.engine"
 remdebug.engine.start()
 remdebug.engine.config { host = your-ip-address }

-- Tips
 @ Using package.loadlib gives you the advantage of defining a full qualified path like:
    local fnInit,err =  package.loadlib("E:\\hunspell.dll", "luaopen_hunspell")
    assert(type(fnInit) == "function",err)
    fnInit()
 
 @ If a luamodule itself has some unfilled dependecies ( on eg libpthreads) Lua will note "module not found".
     Using Dependency Walker / and exclude  (gccs) lib path will help revealing details to fix.
 
 @ http://lua-users.org/wiki/SciteLuaDll is slightly dated, but still correct.
 
-- Further Information
 ... can be obtained from within the source Tree - scintilla/include/scintilla.iface
 ... or online at http://www.scintilla.org/SciTEExtension.html | www.scintilla.org/PaneAPI.html |

-- Writing Modules in different Languages
 Addons can be written in  any Language able to send WM_COPYDATA Messages to Scites "Director" HWND. 
 Eg a SciteLua function called "foo" without arguments, can be called by sending a WM_COPYDATA message like "extender:foo".
 see http://stevedonovan.github.io/winapi/api.html

