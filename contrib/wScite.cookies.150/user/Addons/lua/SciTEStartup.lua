-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript_reload")

defaultHome = props["SciteDefaultHome"].."\\user"
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.path=package.path..";C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua"
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-extman\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

--~ If available, use spawner-ex to help reduce flickering within scite_popen
local pathSpawner= props["spawner.extension.path"]
if not pathSpawner~="" then
 fnInit,err= package.loadlib(pathSpawner.."/spawner-ex.dll",'luaopen_spawner')
 if not err then fnInit() end
end

--lua >=5.2.x renamed functions: 
local unpack = table.unpack or unpack
math.mod=math.fmod or math.mod
string.gfind=string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- Load extman.lua (also "eventmanager.lua")
dofile(props["SciteDefaultHome"]..'\\user\\Addons\\lua\\mod-extman\\extman.lua')
-- ################################

-- ################################
function OnSwitchFile(p)
        scite.SendEditor(SCI_SETCARETFORE, 255, 0)
end