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
-- Load extman.lua
-- This will automatically run any lua script located in \User\lua\lua-scite
dofile(myScripts.."mod-extman"..dirSep.."eventmanager.lua")
dofile(myScripts.."mod-extman"..dirSep.."extman.lua")
-- Load cTags Browser
dofile(myScripts.."mod-ctags"..dirSep.."ctagsd.lua")
-- Initialize Project support
	dofile(myScripts..'SciTEProject.lua')

	
--  Lua Samples
-- OnInit()
-- called after above and only once when Scite starts (SciteStartups DocumentReady)

function OnInit()
	--scite.MenuCommand(IDM_FOLDMARGIN)
end
