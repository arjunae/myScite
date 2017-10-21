-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

--------------------------------- Lua Addons
--  Sidebar packagePath
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\lua\\?.lua;"

-- Load Extman
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-extman\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\extman.lua')


-- ##################  Lua Samples #####################
--   ##############################################

function markLinks()
--
-- search for textlinks and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
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
