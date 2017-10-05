-- track the amount of allocated memory 
session_used_memory=collectgarbage("count")*1024

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript_reload")

myHome = props["SciteUserHome"].."/user"
package.path = package.path ..";"..myHome.."\\Addons\\lua\\lua\\?.lua;".. ";"..myHome.."\\Addons\\lua\\lua\\socket\\?.lua;"
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-extman\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."\\Addons\\lua\\c\\?.dll;"

--lua >=5.2.x renamed functions: 
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- Load extman.lua 
dofile(myHome..'\\Addons\\lua\\mod-extman\\extman.lua')

-- chainload eventmanager / extman remake used by some lua mods
dofile(myHome..'\\Addons\\lua\\mod-extman\\eventmanager.lua')

-- Load mod-mitchell 
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-mitchell\\?.lua;"
dofile(myHome..'\\Addons\\lua\\mod-mitchell\\scite.lua')

-- Load Orthospell 
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-hunspell\\?.lua;"
dofile(myHome..'\\Addons\\lua\\mod-orthospell\\orthospell.lua')

-- Load Sidebar
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
dofile(myHome..'\\Addons\\lua\\mod-sidebar\\URL_detect.lua')

-- ##################  Lua Samples #####################
-- ###############################################

function markLinks()
--
-- search for textlinks and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
-- todo: Use variables for Themebility
-- 
	local marker_a=10 -- The whole Textlink
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
-- Now mark any params and their Values in above text URLS
--
	local marker_b=11 -- The URL Param
	editor.IndicStyle[marker_b] = INDIC_TEXTFORE
	editor.IndicFore[marker_b]  = props["colour.url_param"]

	local marker_c=12 -- The URL Params Value
	editor.IndicStyle[marker_c] = INDIC_TEXTFORE
	editor.IndicFore[marker_c]  = props["colour.url_param_value"]
	
	mask_b="%?[a-zA-Z0-9%_+%.%-%[%]?[=]" -- ?& Any alphaNum any _+.- Ends with space, newline, tab < " or '
	mask_c="=[a-zA-Z0-9%_+%.%-]?[^& \r\n\t\"\'<]" -- =  Any alphaNum any _+.- Ends with space, newline, tab < " or '
	
	local sA,eA = editor:findtext(mask_b, SCFIND_REGEXP, 0)
	while sA do
		if editor:IndicatorValueAt(marker_a,sA)==1 then
			EditorMarkText(sA, (eA-sA), marker_b) 
		end -- common.lua
		sA,eA = editor:findtext( mask_b, SCFIND_REGEXP, sA+1)
	end
	
	local sB,eB = editor:findtext(mask_c, SCFIND_REGEXP, 0)	
	while sB do
		if editor:IndicatorValueAt(marker_a,sB)==1 then
			EditorMarkText(sB+1, (eB-sB)-1, marker_c) 
		end -- common.lua
		sB,eB = editor:findtext( mask_c, SCFIND_REGEXP, sB+1)
	end
	
	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) -- Neals funny bufferSwitch Cursor colors :) 
end

scite_OnOpenSwitch(markLinks)
-- print(editor.StyleAt[1])
-- scite.MenuCommand(IDM_MONOFONT) -- Test MenuCommand
