-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript_reload")

defaultHome = props["SciteDefaultHome"]
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
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- Load extman.lua (also "eventmanager.lua")
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-extman\\extman.lua')

-- Load mod-mitchell 
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-mitchell\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-mitchell\\scite.lua')

-- Load mod-macros
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-macros\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-macros\\macros.lua')

-- Load Orthospell 
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-hunspell\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-orthospell\\orthospell.lua')

-- Load Sidebar (which uses "eventmanager.lua")
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-sidebar\\URL_detect.lua')

-- ################## Lua Samples #####################
	
function markLinks()
--
-- search for links and highlight them HTTP://ww.bla.de
--
	local marker= 1
	prefix="http.*://"  -- Rules: Begins with http(s):// 
	body=".*\\." 	-- must have at least one dot in 
	suffix="[^ \t\r\n\"\']+" 	-- ends with space, newline, " or '
	mask=prefix..body..suffix
	--EditorClearMarks(marker)
	local s,e = editor:findtext( mask, SCFIND_REGEXP, 0)
	while s do
		EditorMarkText(s, e-s, marker) 
		s,e =  editor:findtext( mask, SCFIND_REGEXP, s+1)
	end
end

function OnSwitchFile(p)
	--
	-- Neals funny Cursor colors :) for loadFile / bufferSwitch   
	--
	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) 
	 markLinks()
end

-- Test MenuCommand
--scite.MenuCommand(IDM_MONOFONT)
