-- mySciTE's Development Lua Startup Script t.kani@gmx.net

--io.stdout:setvbuf("no")
--_G.session_used_memory=collectgarbage("count")*1024 -- track the amount of lua allocated memory

--lua >=5.2.x renamed functions:
unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end

myHome = props["SciteDefaultHome"]..dirSep.."user"..dirSep
LUA_PATH=myHome.."\\opt\\lua\\rocks\\" -- std lua related scripts
package.path = package.path ..";"..myHome.."opt/lua/?.lua;"..myHome.."opt/lua-scite/?.lua";
package.cpath = package.cpath .. ";"..myHome.."opt/c/?.dll;"..myHome.."opt/lua-scite/?.dll";

if not GTK then
	package.path = string.gsub(package.path,"/","\\")
	package.cpath = string.gsub(package.cpath,"/","\\")
end

--dofile(myHome.."opt"..dirSep.."eventmanager.lua")

-- Loading extman.lua will automatically run any lua script located in \user\opt\lua-scite
dofile(myHome.."opt"..dirSep.."extman.lua")
dofile(myHome.."opt"..dirSep.."macros.lua")
-- Initialize Project support last
-- dofile(myHome.."opt"..dirSep.."ctags.lua")
-- dofile(myHome.."opt"..dirSep.."SciTEProject.lua")

--  Lua Samples
-- called after above and only once when Scite starts (SciteStartups DocumentReady)
function OnInit()

end
