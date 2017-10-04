-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript_reload")

defaultHome = props["SciteUserHome"].."/user"
package.path = package.path ..";"..defaultHome.."/Addons/lua/lua/?.lua;".. ";"..defaultHome.."/Addons/lua/lua/socket/?.lua;"
package.path = package.path .. ";"..defaultHome.."/Addons/lua/mod-extman/?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."/Addons/lua/c/?.so;"

--lua >=5.2.x renamed functions: 
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- Load extman.lua
dofile(defaultHome..'/Addons/lua/mod-extman/extman.lua')

-- chainload eventmanager / extman remake used by some lua mods
dofile(defaultHome..'/Addons/lua/mod-extman/eventmanager.lua')

-- Load mod-mitchell 
package.path = package.path .. ";"..defaultHome.."/Addons/lua/mod-mitchell/?.lua;"
dofile(defaultHome..'/Addons/lua/mod-mitchell/scite.lua')


-- ##################  Lua Samples #####################
-- ###############################################

function markLinks()
--
-- search for textlinks and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
--
	local marker_a=10
	editor.IndicStyle[marker_a] = INDIC_COMPOSITIONTHIN
	editor.IndicFore[marker_a] = 0xBE3333
	
	prefix="http[:|s]+//"  -- Rules: Begins with http(s):// 
	body="[a-zA-Z0-9]?." 	-- followed by a word  (eg www or the domain)
	suffix="[^ \r\n\t\"\'<]+" 	-- ends with space, newline,tab < " or '
	mask = prefix..body..suffix 
	EditorClearMarks(marker_a) -- common.lua
	local s,e = editor:findtext( mask, SCFIND_REGEXP, 0)
	while s do
		EditorMarkText(s, e-s, marker_a) -- common.lua
		s,e =  editor:findtext( mask, SCFIND_REGEXP, s+1)
	end
	
--	
-- Now mark any param Values in above text URLS
--
	local marker_b=11
	editor.IndicStyle[marker_b] = INDIC_TEXTFORE
	editor.IndicFore[marker_b]  = 0x708ADD
	mask_b="=[a-zA-Z0-9%_+%.%-]?[^& \r\n\t\"\'<]" -- Any alphaNum any _+.- Ends with space, newline,tab < " or '
	local s,e = editor:findtext(mask_b , SCFIND_REGEXP, 0)

	while s do
		if editor:IndicatorValueAt(marker_a,s)==1 then
			EditorMarkText(s, (e-s), marker_b) 
		end -- common.lua
		s,e =  editor:findtext( mask_b, SCFIND_REGEXP, s+1)
	end
	
	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) -- Neals funny bufferSwitch Cursor colors :) 
end

scite_OnOpenSwitch(markLinks)
-- print(editor.StyleAt[1])
-- scite.MenuCommand(IDM_MONOFONT) -- Test MenuCommand
