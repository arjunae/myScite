-- # mySciTE Development Lua Startup Script t.kani@gmx.net #
										
--io.stdout:setvbuf("no")
--_G.session_used_memory=collectgarbage("count")*1024 -- track the amount of lua allocated memory

--lua >=5.2.x renamed functions:
_G.unpack = table.unpack or unpack
_G.math.mod = math.fmod or math.mod
_G.string.gfind = string.gmatch or string.gfind
unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(arr) with #arr
GTK = props['PLAT_GTK']
if GTK then dirSep = '/' else dirSep = '\\' end

--__--__--__--__--__--__--__--__

myHome = props["SciteDefaultHome"]..dirSep.."user"..dirSep
LUA_PATH=myHome.."\\opt\\lua\\rocks\\" -- std lua related scripts
package.path = package.path ..";"..myHome.."opt/lua/?.lua;"..myHome.."opt/lua-scite/?.lua";
package.cpath = package.cpath .. ";"..myHome.."opt/c/?.dll;"..myHome.."opt/lua-scite/?.dll";

if not GTK then
	package.path = string.gsub(package.path,"/","\\")
	package.cpath = string.gsub(package.cpath,"/","\\")
end

-- Loading extman.lua will automatically run any lua script located in \user\opt\lua-scite
dofile(myHome.."opt"..dirSep.."extman.lua")
dofile(myHome.."opt"..dirSep.."macros.lua")
--dofile(myHome.."opt"..dirSep.."mod-sidebar\\sidebar.lua")
-- Initialize Project support last
 dofile(myHome.."opt"..dirSep.."ctags.lua")
 dofile(myHome.."opt"..dirSep.."SciTEProject.lua")

--__--__--__--__--__--__--__--__

-- ##################  Lua Samples #####################
--   ##############################################

function HighlightLinks()
--
-- highlight Links See Indicators@http://www.scintilla.org/ScintillaDoc.html
	local marker_a=10 -- The whole URL
	if editor.Lexer~=1 then -- Performance: no Null Lexer	
		EditorClearMarks(marker_a) -- common.lua 
		editor.IndicStyle[marker_a] = INDIC_TEXTFORE
		editor.IndicFore[marker_a] = 0x994444
		prefix="http[:|s]+//"  -- Rules: Begins with http(s):// 
		body="[a-zA-Z0-9]?." 	-- followed by a word  (eg www or the domain)
		suffix="[^ \r\n\t\"\'<]+" 
		str = prefix..body..suffix 
		local sNr,eNr = editor:findtext( str, SCFIND_REGEXP, 0)
		while eNr do
			EditorMarkText(sNr, eNr-sNr, marker_a) -- common.lua
			sNr,eNr =  editor:findtext( str, SCFIND_REGEXP, sNr+1)
		end
	end

end

function myScite_SwitchFile()
	if buffer and props["FilePath"]~="" then 
		buffer.size= file_size(props["FilePath"])
		if buffer.size < 262144 then HighlightLinks() end
	end
end

--__--__--__--__--__--__--__--__


-- called after above and only once when Scite starts (SciteStartups DocumentReady)
function OnInit()
  -- Events for Indicators
  scite_OnOpenSwitch(myScite_SwitchFile)
end
--__--__--__--__--__--__--__--__
