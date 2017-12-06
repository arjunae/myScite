--
-- mySciTE's Lua Startup Script 2017 Marcedo@HabMalNeFrage.de
--

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

myHome = props["SciteUserHome"].."/user"
defaultHome = props["SciteDefaultHome"]
package.path = package.path ..";"..myHome.."\\Addons\\lua\\lua\\?.lua;".. ";"..myHome.."\\Addons\\lua\\lua\\socket\\?.lua;"
package.path = package.path .. ";"..myHome.."\\Addons\\lua\\mod-extman\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."\\Addons\\lua\\c\\?.dll;"

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
dofile(myHome..'\\Addons\\lua\\mod-sidebar\\URL_detect.lua')

-- Load cTags Browser
dofile(myHome..'\\Addons\\lua\\mod-ctags\\ctagsd.lua')

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
	editor.IndicFore[marker_mail] = 0xB72233
	
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
	editor.IndicFore[marker_guid] = 0x577785
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

function StyleStuff()
---
--- highlite http and eMail links and GUIDs
---
	local AC_MAX_SIZE =131072 --131kB
	local fSize =0
	if props["FileName"] ~="" then fSize= file_size(props["FilePath"]) end
	if fSize < AC_MAX_SIZE then 
		scite_OnOpenSwitch(markLinks)
		scite_OnOpenSwitch(markeMail)
		scite_OnOpenSwitch(markGUID)	  
	end
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function HandleProject()
--
-- handle Project Folders (ctags, Autocomplete & highlitening)
--

	if props["SciteDirectoryHome"] ~= props["FileDir"] then
		props["project.path"] = props["SciteDirectoryHome"]
		props["project.info"] = "{"..props["project.name"].."}->"..props["FileNameExt"]
		buffer.projectName= props["project.name"]
	else
		props["project.info"] =props["FileNameExt"] -- Display filename in StatusBar1 
	end
	dofile(myHome..'\\macros\\AutoComplete.lua')
end

-- Register the Autocomplete event Handlers early.
HandleProject()
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function AppendCTags()
--
-- Search the File for new CTags and append them.
--
	if props["project.name"]~="" then
		ctagsBin=props["project.ctags.bin"]
		ctagsOpt=props["project.ctags.opt"]
		if ctagsBin and ctagsOpt then ctagsCMD=ctagsBin.." --append=yes "..ctagsOpt.." "..props["FilePath"] end
		scite_Popen(ctagsCMD)
	end
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function OnInit() 
--
-- called after above and only once when Scite starts (SciteStartups DocumentReady)
--

	scite_OnOpenSwitch(HandleProject)
	scite_OnSave(AppendCTags())
	
	scite_OnOpenSwitch(StyleStuff)
	
-- print("Modules Memory usage:",collectgarbage("count")*1024-_G.session_used_memory)	
-- scite.MenuCommand(IDM_MONOFONT) -- force Monospace	
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--print("startupScript_reload")
--print(editor.StyleAt[1])
--print(props["Path"])
