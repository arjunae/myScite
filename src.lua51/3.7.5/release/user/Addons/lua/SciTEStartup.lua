--
-- mySciTE's Test Lua Startup Script 2017 Marcedo@HabMalNeFrage.de
--

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

myHome = props["SciteUserHome"].."/user"
defaultHome = props["SciteDefaultHome"]
package.path = package.path ..";"..myHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."\\Addons\\lua\\c\\?.dll;"

--lua >=5.2.x renamed functions:
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

--~~~~~~~~~~~~~
-- track the amount of lua allocated memory
_G.session_used_memory=collectgarbage("count")*1024

-- ##################  Lua Samples #####################
--   ##############################################

function OnInit() 
--
-- called after above and only once when Scite starts (SciteStartups DocumentReady)
--
	
end
--print("startupScript_reload")
--print(editor.StyleAt[1])
-- scite.MenuCommand(IDM_MONOFONT) -- Test MenuCommand
