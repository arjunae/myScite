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


if props["PLAT_WIN"] then
	myHome = props["SciteUserHome"].."\\user"
	defaultHome = props["SciteDefaultHome"]
	package.path = package.path ..";"..myHome.."\\Addons\\lua\\lua\\?.lua;".. ";"..myHome.."\\Addons\\lua\\lua\\socket\\?.lua;"
	package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-extman\\?.lua;"
	package.cpath = package.cpath .. ";"..myHome.."\\Addons\\lua\\c\\?.dll;"
	-- Load extman.lua
	-- This will automatically run any lua script located in \User\Addons\lua\lua
	dofile(myHome..'\\Addons\\lua\\mod-extman\\extman.lua')
	-- Load cTags Browser
	dofile(myHome..'\\Addons\\lua\\mod-ctags\\ctagsd.lua')
end

if props["PLAT_GTK"]==1 then
	myHome = props["SciteUserHome"].."/user"
	defaultHome = props["SciteDefaultHome"]
	package.path = package.path ..";"..myHome.."/Addons/lua/lua/?.lua;".. ";"..myHome.."/Addons/lua/lua/socket/?.lua;"
	package.path = package.path .. ";"..myHome.."/Addons/lua/mod-extman/?.lua;"
	package.cpath = package.cpath .. ";"..myHome.."/Addons/lua/c/?.dll;"
		-- Load extman.lua
	-- This will automatically run any lua script located in \User\Addons\lua\lua
	dofile(myHome..'/Addons/lua/mod-extman/extman.lua')
	-- Load cTags Browser
	dofile(myHome..'/Addons/lua/mod-ctags/ctagsd.lua')
end
-- ##################  Lua Samples #####################
--   ##############################################

function OnLoad() 
	--print(editor.StyleAt[1])
	-- scite.MenuCommand(IDM_MONOFONT) -- Test MenuCommand
end


