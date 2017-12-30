--
-- mySciTE's Lua Startup Script 2017 Marcedo@HabMalNeFrage.de
--
--~~~~~~~~~~~~~

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

myHome = props["SciteUserHome"].."/user"
defaultHome = props["SciteDefaultHome"]
package.path = package.path ..";"..myHome.."\\Addons\\lua\\lua\\?.lua;".. ";"..myHome.."\\Addons\\lua\\lua\\socket\\?.lua;"
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-extman\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."\\Addons\\lua\\c\\?.dll;"

dirSep, GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end

--lua >=5.2.x renamed functions:
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x
--~~~~~~~~~~~~~

-- track the amount of lua allocated memory
_G.session_used_memory=collectgarbage("count")*1024
	
-- Load extman.lua
-- This will automatically run any lua script located in \User\Addons\lua\lua
dofile(myHome..'\\Addons\\lua\\mod-extman\\extman.lua')

-- chainload eventmanager / extman remake used by some lua mods
dofile(myHome..'\\Addons\\lua\\mod-extman\\eventmanager.lua')

-- Load mod-mitchell
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-mitchell\\?.lua;"
--dofile(myHome..'\\Addons\\lua\\mod-mitchell\\scite.lua')
		
-- Load Sidebar
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
dofile(myHome..'\\Addons\\lua\\mod-sidebar\\sidebar.lua')

-- Load cTags Browser
dofile(myHome..'\\Addons\\lua\\mod-ctags\\ctagsd.lua')

-- Load Project support functions
dofile(myHome..'\\Addons\\lua\\SciTEProject.lua')

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ##################  Lua Samples #####################
--   ##############################################

function markLinks()
--
-- search for textlinks and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
-- https://www.test.de/

	local marker_a=10 -- The whole Textlink
	editor.IndicStyle[marker_a] = INDIC_COMPOSITIONTHIN
	editor.IndicFore[marker_a] = 0xBE3344

	if editor.Lexer~=1 then -- Performance: Exclude Null Lexer	
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
	end

--	
-- Now mark any params and their Values - based in above text URLS
-- http://www.test.de/?key1=test&key2=a12

	-- Keys 
	local marker_b=11 -- The URL Param
	editor.IndicStyle[marker_b] = INDIC_TEXTFORE
	if props["colour.url_param"]=="" then props["colour.url_param"] = "0x05A750" end
	editor.IndicFore[marker_b]  = props["colour.url_param"] 
	
	if editor.Lexer~=1 then -- Performance: Exclude Null Lexer	
		mask_b="[?&].*[=]" --Begin with ?& Any Char/Digit Ends with =
		local sA,eA = editor:findtext(mask_b, SCFIND_REGEXP, 0)
		while sA do
			if editor:IndicatorValueAt(marker_a,sA)==1 then
				EditorMarkText(sA, (eA-sA), marker_b)
			end -- common.lua
			sA,eA = editor:findtext( mask_b, SCFIND_REGEXP, sA+1)
		end

		-- Values
		local marker_c=12 -- The URL Params Value
		editor.IndicStyle[marker_c] = INDIC_TEXTFORE
		if props["colour.url_param_value"]=="" then props["colour.url_param_value"] = "0x3388B0" end
		editor.IndicFore[marker_c]  = props["colour.url_param_value"] 
		mask_c="=[^& <]+[a-zA-Z0-9]?" -- Begin with = ends with Any alphaNum

		local sB,eB = editor:findtext(mask_c, SCFIND_REGEXP, 0)
		while sB do
			if editor:IndicatorValueAt(marker_a,sB)==1 then
				EditorMarkText(sB+1, (eB-sB)-1, marker_c)
			end -- common.lua
			sB,eB = editor:findtext( mask_c, SCFIND_REGEXP, sB+1)
		end
	end

	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) -- Neals funny bufferSwitch Cursor colors :)
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function markeMail()
-- 
-- search for eMail Links and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
-- d.Name@users.source-server.net

	local marker_mail=13 -- The whole Textlink
	editor.IndicStyle[marker_mail] = INDIC_COMPOSITIONTHIN
	if props["colour.email"]=="" then props["colour.email"] = "0xB72233" end
	editor.IndicFore[marker_mail] = props["colour.email"]
	
	if editor.Lexer~=1 then -- Performance: Exclude Null Lexer	
		prefix="[a-zA-Z0-9._-]+@" -- first part till @
		body="[a-zA-Z0-9]+.*[.]" -- (sub.)domain part
		suffix="[a-zA-Z]+" -- TLD
		mask = prefix..body..suffix
		EditorClearMarks(marker_mail) -- common.lua
		local startpos,endpos = editor:findtext( mask, SCFIND_REGEXP, 0)
		while startpos do
			EditorMarkText(startpos, endpos-startpos, marker_mail) -- common.lua
			startpos,endpos =  editor:findtext( mask, SCFIND_REGEXP, startpos+1)
		end
	end
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function markGUID()
--
-- search for GUIDS and highlight them. See Indicators@http://www.scintilla.org/ScintillaDoc.html
-- {D3A4D768-B42D-4B87-B5C2-8236EA49BA6F}

	local marker_guid=14 -- The whole Textlink
	editor.IndicStyle[marker_guid] = INDIC_TEXTFORE
	if props["colour.guid"]=="" then props["colour.guid"] = "0xB72244" end
	editor.IndicFore[marker_guid] = props["colour.guid"]
	
-- Scintillas RESearch.cxx doesnt support match counting, so just define the basic guid format:
	mask = "........-\\w\\w\\w\\w-\\w\\w\\w\\w-\\w\\w\\w\\w-............"
	if editor.Lexer~=1 then -- Performance: Exclude Null Lexer	
		EditorClearMarks(marker_guid) -- common.lua
		local startpos,endpos = editor:findtext( mask, SCFIND_REGEXP, 0)
		while startpos do
			EditorMarkText(startpos, endpos-startpos, marker_guid) -- common.lua
			startpos,endpos =  editor:findtext( mask, SCFIND_REGEXP, startpos+1)
		end
	end
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function myScite_OpenSwitch()

	local AC_MAX_SIZE =262144 --260kB
	local fSize =0

	if buffer and props["FilePath"]~="" then 
		buffer.size= file_size(props["FilePath"]) 
		if buffer.size < AC_MAX_SIZE then 
			markLinks()
			markeMail()
			markGUID()
			DetectUTF8()
		else
			props["highlight.current.word"]=0
			props["find.strip.incremental"]=1
		end
	end
	
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function OnInit() 
--
-- called after above and only once when Scite starts (SciteStartups DocumentReady)
--

	-- Event Handlers
	scite_OnOpenSwitch(CTagsUpdateProps,false,"")
	scite_OnSave(CTagsRecreate)
	scite_OnOpenSwitch(myScite_OpenSwitch)
	
-- print("Modules Memory usage:",collectgarbage("count")*1024-_G.session_used_memory)	
-- scite.MenuCommand(IDM_MONOFONT) -- force Monospace	
--print("startupScript_reload")
--print(editor.StyleAt[1])
--print(props["Path"])

end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
