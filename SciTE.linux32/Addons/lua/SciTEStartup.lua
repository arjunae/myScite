-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."/Addons/?.lua;".. ";"..defaultHome.."/Addons/lua/lua/?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."/Addons/lua/c/?.so;"

---- SciTEStartup.lua gets called by extman, to ensure its available here.
-- Load mod-mitchell 
package.path = package.path .. ";"..defaultHome.."/Addons/lua/mod-mitchell/?.lua;"
dofile(props["SciteDefaultHome"]..'/Addons/lua/mod-mitchell/scite.lua')

-- Load Orthospell 
package.path = package.path .. ";"..defaultHome.."/Addons/lua/mod-hunspell/?.lua;"
dofile(props["SciteDefaultHome"]..'/Addons/lua/mod-orthospell/orthospell.lua')

-- ##################  Lua Samples #####################
-- ###############################################

function markLinks()
--
-- search for textlinks and highlight them http://bla.de/bla
--
	local marker=10
	editor.IndicStyle[marker] = INDIC_DIAGONAL --INDIC_COMPOSITIONTHIN
	editor.IndicFore[marker]  = 0xDE0202
	
	prefix="http[:|s]+//"  -- Rules: Begins with http(s):// 
	body="[a-zA-Z0-9]?." 	-- followed by a word  (eg www or the domain)
	suffix="[^ \r\n\"\'<]+" 	-- ends with space, newline < " or '
	mask=prefix..body..suffix 
	EditorClearMarks(marker) -- common.lua
	local s,e = editor:findtext( mask, SCFIND_REGEXP, 0)
	while s do
		EditorMarkText(s, e-s, marker) -- common.lua
		s,e =  editor:findtext( mask, SCFIND_REGEXP, s+1)
	end
end

function OnOpen(p)
	 markLinks()
end

function OnSwitchFile(p)
	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) 	-- Neals funny bufferSwitch Cursor colors :)
	markLinks()
end

-- Test MenuCommand
-- scite.MenuCommand(IDM_MONOFONT)
