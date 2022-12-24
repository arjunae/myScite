-- mySciTE's Lua Startup Script 2022 Marcedo@HabMalNeFrage.de

-- Windows requirement to immediately see all lua output.
io.stdout:setvbuf("no")

dirSep, GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end
myHome = props["SciteDefaultHome"]..dirSep.."user"
LUA_PATH=myHome.."\\Addons\\lua\\lua\\" -- lua rocks related lua scripts
package.path = package.path ..";"..myHome.."\\opt\\lua\\?.lua;"..myHome.."\\opt\\lua-scite\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."\\opt\\lua-scite\\?.dll;"
if not GTK then
	package.path = string.gsub(package.path,"/","\\")
	package.cpath = string.gsub(package.cpath,"/","\\")
end

-- Startup script might be called multiple times with ext.lua.auto.reload and saving
-- so ensure to load those LuaMods only once.
if (true) then
--lua >=5.2.x renamed functions:
_G.unpack = table.unpack or unpack
_G.math.mod = math.fmod or math.mod
_G.string.gfind = string.gmatch or string.gfind
_G.os.exit= function() error("Catched os.exit from quitting SciTE.\n") end
--lua >=5.2.x replaced table.getn(x) with #x
_G.session_used_memory=collectgarbage("count")*1024 -- track the amount of lua allocated memory

-- load eventmanager / extman remake used by some lua mods
	dofile(myHome..'\\opt\\eventmanager.lua')
	
	-- Load extman.lua
	-- This will automatically run any lua script located in \user\opt\lua-scite
	dofile(myHome..'\\opt\\extman.lua')
	--dofile(myHome..'\\opt\\macros.lua')
	
	-- Load Debugging support
	package.path = package.path .. ";"..myHome.."\\opt\\mod-scite-debug\\?.lua;"
	dofile(myHome..'\\opt\\mod-scite-debug\\debugger.lua')
	
	-- Load Sidebar
	-- workaround: loading the sidebar here avoids problems with ext.lua.auto.reload
	package.path = package.path .. ";"..myHome.."\\opt\\mod-sidebar\\?.lua;"
	--dofile(myHome..'\\opt\\mod-sidebar\\sidebar.lua')
	
	-- Load mod-mitchell
	package.path = package.path .. ";"..myHome.."\\opt\\mod-mitchell\\?.lua;"
	--dofile(myHome..'\\opt\\mod-mitchell\\scite.lua')

	-- Initialize Project support last
	dofile(myHome.."\\opt\\ctags.lua")
	dofile(myHome..'\\opt\\SciTEProject.lua')
end

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
-- Now mark any params and their Values - based ob above found text URL's
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
				EditorMarkText(sB+1, (eB-sB)-1, marker_c) -- common.lua
			end 
			sB,eB = editor:findtext( mask_c, SCFIND_REGEXP, sB+1)
		end
	end

	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) -- Neals funny bufferSwitch Cursor colors :)
end

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

function myScite_OpenSwitch()

	local AC_MAX_SIZE = 262144 --260kB
	local fSize =0
	
	if buffer and props["FilePath"]~="" then 
		buffer.size= file_size(props["FilePath"])
		if buffer.size < AC_MAX_SIZE then 
			markLinks()
			markeMail()
			markGUID()
			DetectUTF8()
			props["find.strip.incremental"]=2
			props["highlight.current.word"]=1	
			props["status.msg.words_found"]="| Words Found: $(highlight.current.word.counter)"			
		else
			props["highlight.current.word"]=0
			props["find.strip.incremental"]=1
			props["status.msg.words_found"]=""
		end
	end
end
			
function OnInit() 
--
-- called after above and only once when Scite starts (SciteStartups DocumentReady)
--
	--editor:GrabFocus()  -- Ensure editors focus
	
	-- check SciLexer once per session and inform the User if its a nonStock Version.
	local SLHash
	if not SLHash then
	SLHash=fileHash( props["SciteDefaultHome"].."\\SciLexer.dll" )  
		if SLHash and SLHash~=props["SciLexerHash"] then print("common.lua: You are using a modified SciLexer.dll with CRC32 Hash: "..SLHash) end
	end
	
	-- Event Handlers
	scite_OnKey( function()  props["CurrentPos"]=editor.CurrentPos end ) -- keep Track of current Bytes Offset (for Statusbar)
--	checkUpdates() -- check for a new version using githubs readme.md
	myScite_OpenSwitch() -- apply Indicators

-- print("Modules Memory usage:",collectgarbage("count")*1024-_G.session_used_memory)	
-- print("startupScript_onInit")

end
