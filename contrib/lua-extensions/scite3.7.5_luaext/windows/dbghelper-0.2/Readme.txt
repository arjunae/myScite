
  --==coDebug was initially a test Prototype but will be loosly enhanced within this gist.==--
  
  It circumvents two problem of scites Luaextension.
    First: Its running in the same Thread. So its not possible to continously loop without blocking scite.
    Second: Currently scite has no equivalent to either io.read() or os.exit()
    How: A clib called dbghelper injects a lua yield call within Luas internal debug table.
         That way, the debuggee will be yielded (on count events) such releasing control back to the steering lua script.
           (Gunnar Zötl <gz@tset.de>) (http://tset.de/dbghelper/index.html)
           
   Status: Test Prototype - 
   Commands available:
      coDebug> h
      (w) where
      (t) trace
      (l) locals
      (s) step
      (.) eval as lua
      (q) quit


--------------------
Original dbghelper Readme
--------------------
dbghelper is a module for lua 5.1 and 5.2 to aid debugging of lua programs.
It injects a function resumeuntil into the debug table, which can resume a coroutine until a debug event occurs or the coroutine yields or returns.

Documentation
Usage
require "dbghelper"

cr = coroutine.create(function_to_debug)
ok, what = debug.resumeuntil(cr, mask, count, ...) 

Arguments

cr
    coroutine to debug
mask, count
    as for debug.sethook
...
    extra arguments to pass to the coroutine resume function (only use if the coroutine has yielded or on the first call)

Return values

ok
    true if the coroutine can be resumed, false if not
what
    event that caused resumeuntil to return, can be any one of

        'line', 'count', 'call', 'tail call', 'return', 'tail return' or 'yield' if ok is true,
        'return' or 'error' if ok is false.

Notes

    the mask and count arguments can be nil. If both are nil, resumeuntil will just resume the coroutine until it returns, yields or throws an error.
    if an error occurred, the error message is returned as the third return value from resumeuntil
    if ok and what are true and 'yield', the debugged function has yielded and arguments passed to yield are returned as third and following return values from resumeuntil
    if ok and what are false and 'return', the debugged function has returned and any return values are returned as third and following return values from resumeuntil
    if ok is true and what is anything but 'yield', this signals that the corresponding debug hook has been invoked.
    only lua 5.1 will return 'tail return', only lua 5.2 will return 'tail call'.

Look at the included dbg_test.lua for some examples.