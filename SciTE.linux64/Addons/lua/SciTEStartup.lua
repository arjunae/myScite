
defaultHome=props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."/Addons/?.lua;"
package.path = package.path .. ";"..defaultHome.."/Addons/lua-modules/lua/?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."/Addons/lua-modules/c/?.dll;"

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

-- Extman
dofile(props["SciteDefaultHome"]..'/Addons/lua-modules/extman.lua')
