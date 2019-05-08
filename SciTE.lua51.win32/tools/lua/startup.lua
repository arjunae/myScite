
-- track the amount of allocated memory 
session_used_memory=collectgarbage("count")*1024

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript loaded")

-- Path to current Files Dir- Ends with a trailing slash 
local luaHome=""
--local s,e,filePath=string.find( arg[0], "(.+[/\\]).-" )
local filePath=debug.getinfo(1).source:match("@(.*[\\/]).+$") 
if(filePath) then 
	luaHome=filePath.."..\\.." -- fully qualified Path
else
	luaHome="..\\.."
end

--print("luaHome: "..luaHome)
package.path = package.path .. ";"..luaHome.."\\User\\Addons\\lua\\lua\\?.lua;"
package.path = package.path .. ";"..luaHome.."\\User\\Addons\\lua\\lua\\socket\\?.lua;"
package.path = package.path .. ";"..luaHome.."\\User\\Addons\\lua\\mod-scite-debug\\?.lua;"
package.cpath = package.cpath .. ";"..luaHome.."\\User\\Addons\\lua\\c\\?.dll"
package.cpath = package.cpath .. ";?.dll;"

--lua >=5.2.x renamed functions: 
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- ##################  Lua Samples #####################
-- ###############################################

