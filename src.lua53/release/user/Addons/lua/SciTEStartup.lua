--
-- mySciTE's Development Lua Startup Script 2017 Marcedo@HabMalNeFrage.de
--

io.stdout:setvbuf("no") -- Windows requires this for us to immediately see all lua output.
_G.session_used_memory=collectgarbage("count")*1024 -- track the amount of lua allocated memory

--lua >=5.2.x renamed functions:
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

local dirSep, GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end

myHome = props["SciteUserHome"]..dirSep.."user"
package.path = package.path ..";"..myHome.."/Addons/lua/lua/?.lua;"
package.cpath = package.cpath .. ";"..myHome.."/Addons/lua/c/?.dll;"
if not GTK then
	package.path = string.gsub(package.path,"/","\\")
	package.cpath = string.gsub(package.cpath,"/","\\")
end

myScripts=myHome..dirSep.."Addons"..dirSep.."lua"
-- Load extman.lua
-- This will automatically run any lua script located in \User\Addons\lua\lua
dofile(myScripts..dirSep.."mod-extman"..dirSep.."extman.lua")
-- Load cTags Browser
dofile(myScripts..dirSep.."mod-ctags"..dirSep.."ctagsd.lua")
-- Initialize Project support
dofile(myScripts..dirSep.."SciTEProject.lua")

-- ##################  Lua Samples #####################
--   ##############################################


--
-- OnInit()
-- called after above and only once when Scite starts (SciteStartups DocumentReady)
--
function OnInit() 
	scite_OnOpenSwitch(CTagsUpdateProps,false,"")
	scite_OnSave(CTagsRecreate)
end


