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

-- ################## Lua Samples #####################
		
function markLinks()
--
-- search for links and highlight them http://www.bla.de/bla
--
	local marker= 1
	prefix="http[:|s]+//"  -- Rules: Begins with http(s):// 
	body=".*\\." 	-- followed by any string (www) , must have one dot in 
	suffix="[^ \r\n\"\']+" 	-- ends with space, newline " or '
	mask=prefix..body..suffix
	EditorClearMarks(marker)
	local s,e = editor:findtext( mask, SCFIND_REGEXP, 0)
	while s do
		EditorMarkText(s, e-s, marker) 
		s,e =  editor:findtext( mask, SCFIND_REGEXP, s+1)
	end
end

function OnOpen(p)
	 markLinks()
end

function OnSwitchFile(p)
	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) 	-- Neals funny Cursor colors :) for loadFile / bufferSwitch   
	markLinks()
end

-- Test MenuCommand
-- scite.MenuCommand(IDM_MONOFONT)
