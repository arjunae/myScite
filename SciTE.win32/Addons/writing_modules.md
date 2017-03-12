Writing Modules
Addons can be written in  any Language, which is able to send WM_COPYDATA Messages to Scites "Director" HWND. 
Eg a Lua function called "foo" without arguments, can be called by sending a WM_COPYDATA message like "extender:foo".

see http://stevedonovan.github.io/winapi/api.html

