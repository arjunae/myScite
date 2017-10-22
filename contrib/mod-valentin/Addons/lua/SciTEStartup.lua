-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

--------------------------------- Lua Addons
--  Sidebar packagePath
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\lua\\?.lua;"

-- Load Extman
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-extman\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\extman.lua')


