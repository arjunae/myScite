-- ### mySciTE's Lua Startup Script 2022 t.kani@gmx.net ####
--io.stdout:setvbuf("no")
GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end
myHome = props["SciteDefaultHome"]..dirSep.."user"..dirSep.."opt"..dirSep
LUA_PATH = myHome.."lua\\" -- official lua related scripts
package.path = package.path ..";"..myHome.."lua\\?.lua;"..myHome.."lua-scite\\?.lua;"
package.cpath = package.cpath .. ";"..myHome.."lua-scite\\?.dll;"
if not GTK then
	package.path = string.gsub(package.path,"/","\\")
	package.cpath = string.gsub(package.cpath,"/","\\")
end
--lua >=5.2.x renamed functions:
_G.unpack = table.unpack or unpack
_G.math.mod = math.fmod or math.mod
_G.string.gfind = string.gmatch or string.gfind
--_G.os.exit= function() error("Catched os.exit from quitting SciTE.\n") end
--lua >=5.2.x replaced table.getn(arr) with #arr

-- load eventmanager / extman remake used by some lua mods
--	dofile(myHome..'eventmanager.lua')
	
	-- extman.lua
	-- This will automatically run any lua script located in \user\opt\lua-scite
	dofile(myHome..'extman.lua')

	-- Debugging support
	dofile(myHome..'mod-scite-debug\\debugger.lua')
	
	-- Sidebar- loading the sidebar here avoids problems with ext.lua.auto.reload
	--package.path = package.path .. ";"..myHome.."\\opt\\mod-sidebar\\?.lua;"
	--dofile(myHome..'mod-sidebar\\sidebar.lua')
	
	-- mod-mitchell
	--dofile(myScripts..'opt\\mod-mitchell\\scite.lua')

	-- Initialize Project support last
	dofile(myHome.."ctags.lua")
	dofile(myHome..'SciTEProject.lua')

-- ##################  Lua Samples #####################
--   ##############################################


function HighlightLinks()
--
-- highlight Links See Indicators@http://www.scintilla.org/ScintillaDoc.html
	local markerA=10 -- The whole URL
	if editor.Lexer~=1 then -- Performance: no Null Lexer	
		EditorClearMarks(markerA) -- common.lua 
		editor.IndicStyle[markerA] = INDIC_TEXTFORE
		editor.IndicFore[markerA] = 0x994444
		prefix="http[:|s]+//"  -- Rules: Begins with http(s):// 
		body="[a-zA-Z0-9]?." 	-- followed by a word  (eg www or the domain)
		suffix="[^ \r\n\t\"\'<]+" 	-- ends with space, newline,tab < " or '
		str = prefix..body..suffix 
		local hPos,ePos = editor:findtext( str, SCFIND_REGEXP, 0)
		while ePos do
			EditorMarkText(hPos, ePos-hPos, markerA) -- common.lua
			hPos,ePos =  editor:findtext( str, SCFIND_REGEXP, hPos+1)
		end
	end

--	
-- Highlight params and their Values - based ob above URL's
-- http://www.trendsderzukunft.de/?param=ok&value2=H12

	-- Keys 
	local markerB=11 -- The URL Param
	editor.IndicStyle[markerB] = INDIC_TEXTFORE
	if props["colour.url_param"]=="" then props["colour.url_param"] = "0x604050" end
	editor.IndicFore[markerB]  = props["colour.url_param"] 
	
	if editor.Lexer~=1 then -- No Null Lexer	
		strB="[?&].*[=]" --Begin with ?& Any Char/Digit Ends with =
		local hPos,eA = editor:findtext(strB, SCFIND_REGEXP, 0)
		while hPos do
			if editor:IndicatorValueAt(markerA,hPos)==1 then
				EditorMarkText(hPos+1, (eA-hPos)-1, markerB)
			end -- common.lua
			hPos,eA = editor:findtext( strB, SCFIND_REGEXP, hPos+1)
		end

		-- Values
		local markerC=12 -- The URL Params Value
		editor.IndicStyle[markerC] = INDIC_TEXTFORE
		if props["colour.url_param_value"]=="" then props["colour.url_param_value"] = "0x3377B0" end
		editor.IndicFore[markerC]  = props["colour.url_param_value"] 
		strC="=[^& <]+[a-zA-Z0-9]?" -- Begin with = ends with Any alphaNum

		local hPos,eB = editor:findtext(strC, SCFIND_REGEXP, 0)
		while hPos do
			if editor:IndicatorValueAt(markerA,hPos)==1 then
				EditorMarkText(hPos+1, (eB-hPos)-1, markerC) -- common.lua
			end 
			hPos,eB = editor:findtext( strC, SCFIND_REGEXP, hPos+1)
		end
	
	end

	scite.SendEditor(SCI_SETCARETFORE, 0x615DA1) -- Neals funny bufferSwitch Cursor colors :)
end

function HighlightMail()
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
		str = prefix..body..suffix
		EditorClearMarks(marker_mail) -- common.lua
		local startpos,endpos = editor:findtext( str, SCFIND_REGEXP, 0)
		while startpos do
			EditorMarkText(startpos, endpos-startpos, marker_mail) -- common.lua
			startpos,endpos =  editor:findtext( str, SCFIND_REGEXP, startpos+1)
		end
	end
end


function myScite_OpenSwitch()
	if buffer and props["FilePath"]~="" then 
		buffer.size= file_size(props["FilePath"])
		if buffer.size < 262144 then 
			HighlightLinks()
			--HighlightMail()
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
	scite_OnOpenSwitch(myScite_OpenSwitch)

end




																																												
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
																																													
