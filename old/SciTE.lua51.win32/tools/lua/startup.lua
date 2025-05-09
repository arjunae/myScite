-- track the amount of allocated memory 
session_used_memory=collectgarbage("count")*1024

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript loaded")

-- fully qualified Path to our Lua Interpreter. No trailing Slash
local luaHome=os.getenv('myLuaHome')

-- Path to current Files Dir with a trailing slash. 
local filePath=debug.getinfo(1).source:match("@(.*[\\/]).+$") 

if(luaHome) then 
	filePath=filePath or luaHome.."\\"
	luaHome=luaHome.."\\..\\.."  
else
	print("Please fix: Need OS Env var 'myLuaHome'")
	luaHome=""
end

package.path = package.path .. ";?.lua;"..filePath.."\\?.lua;"
package.path = package.path .. ";"..luaHome.."\\User\\opt\\lua\\?.lua;;"
package.path = package.path .. ";"..luaHome.."\\User\\opt\\lua-scite\\?.lua;"
package.path = package.path .. ";"..luaHome.."\\User\\opt\\lua-scite\\mod-scite-debug\\?.lua;"
package.cpath = package.cpath .. ";"..luaHome.."\\User\\opt\\lua-scite\\c\\?.dll"
package.cpath = package.cpath .. ";?.dll;"

--lua >=5.2.x renamed functions: 
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- ##################  Lua Samples #####################
-- ###############################################

