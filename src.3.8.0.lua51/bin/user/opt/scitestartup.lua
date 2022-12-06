-- mySciTE's Development Lua Startup Script Marcedo@HabMalNeFrage.de

--io.stdout:setvbuf("no")
_G.session_used_memory=collectgarbage("count")*1024 -- track the amount of lua allocated memory

--lua >=5.2.x renamed functions:
unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

local dirSep, GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end

myHome = props["SciteDefaultHome"]..dirSep.."user"
package.path = package.path ..";"..myHome.."/opt/lua/?.lua;"
package.cpath = package.cpath .. ";"..myHome.."/opt/c/?.dll;"
if not GTK then
	package.path = string.gsub(package.path,"/","\\")
	package.cpath = string.gsub(package.cpath,"/","\\")
end

myScripts=myHome..dirSep.."opt"..dirSep
--dofile(myScripts..dirSep.."eventmanager.lua")
dofile(myScripts..dirSep.."macros.lua")

-- Loading extman.lua will automatically run any lua script located in \User\opt\lua-scite
dofile(myScripts..dirSep.."extman.lua")
-- Initialize Project support last
dofile(myScripts..dirSep.."ctags.lua")
dofile(myScripts..'SciTEProject.lua')

	
--  Lua Samples
-- OnInit()
-- called after above and only once when Scite starts (SciteStartups DocumentReady)

function OnInit()
	--scite.MenuCommand(IDM_FOLDMARGIN)
end
