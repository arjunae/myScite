-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript_reload")

myHome = props["SciteDefaultHome"].."/user"
package.path = package.path ..";"..myHome.."\\Addons\\lua\\lua\\?.lua;".. ";"..myHome.."\\Addons\\lua\\lua\\socket\\?.lua;"
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-extman\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."\\Addons\\lua\\c\\?.dll;"

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

-- Load extman.lua 
dofile(myHome..'\\Addons\\lua\\mod-extman\\extman.lua')

-- chainload eventmanager / extman remake used by some lua mods
dofile(myHome..'\\Addons\\lua\\mod-extman\\eventmanager.lua')

-- Load Sidebar
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-ctags\\?.lua;"
dofile(myHome..'\\Addons\\lua\\mod-ctags\\ctagsd.lua')

-- ##################  Lua Samples #####################
-- ###############################################

function markLinks()
--
-- search for textlinks and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
--
	local marker=10
	editor.IndicStyle[marker] = INDIC_COMPOSITIONTHIN
	editor.IndicFore[marker]  = 0xBE3333
	
	prefix="http[:|s]+//"  -- Rules: Begins with http(s):// 
	body="[a-zA-Z0-9]?." 	-- followed by a word  (eg www or the domain)
	suffix="[^ \r\n\t\"\'<]+" 	-- ends with space, newline,tab < " or '
	mask=prefix..body..suffix 
	EditorClearMarks(marker) -- common.lua
	local s,e = editor:findtext( mask, SCFIND_REGEXP, 0)
	while s do
		EditorMarkText(s, e-s, marker) -- common.lua
		s,e =  editor:findtext( mask, SCFIND_REGEXP, s+1)
	end
	
	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) -- Neals funny bufferSwitch Cursor colors :) 
end

scite_OnOpenSwitch(markLinks)

-- scite.MenuCommand(IDM_MONOFONT) -- Test MenuCommand
