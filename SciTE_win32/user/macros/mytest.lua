--go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local defaultHome= props["SciteDefaultHome"]
print("Hello from scitelua!")
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[
for n,v in pairs(_G) do
			 print (n,v)
end
]]
-- ####### LuaCrc32 ######
-- ## crc32 Hash Library
-- ##################
function HashFileCrc32(filename)
	--[[
	crc32.crc32 = function (crc_in, data)
	crc_in -> 4 Byte input CRC, automatically padded.
	data->  input data to apply to CRC, as a Lua string.
	returns -> updated CRC. 
	]]

	C32 = require 'crc32'
	crc32=C32.crc32
	--print ('CyclicRedundancyCheck==', crc32(0, 'CyclicRedundancyCheck')) 

	crccalc = C32.newcrc32()
	crccalc_mt = getmetatable(crccalc)
	assert(crccalc_mt.reset) -- reset to zero
	file = assert(io.open (filename, 'rb'))
	while true do -- read binary file in 4k chunks
		bytes = file:read(4096)
		if not bytes then break end
		crccalc:update(bytes)
	end	

	file:close()
	file=nil
	--print("SciLexer CRC32 Hash:",crccalc:tohex())
	return(crccalc:tohex())
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ####### LuaGui ######
-- ## MsWin widget Library
-- ##################
require 'gui'

function test_gui()
-- testcases for lib GUI

print(gui.to_utf8("UTF"))

	-- First, we need a main window.
	local wnd= gui.window "test-gui"
	wnd:position(200, 200)
	wnd:size(320,500)
	local visible,x,y,panel_width,panel_height = wnd:bounds()
	-- Attach an event handler
	wnd:on_close(function() print("gui window closed") end)
	
	-- define a rtf colorformat 
	local rtf = [[{\rtf {\colortbl; \red30 \green60 \blue90;} ]]

	-- Now, lets create 2 Tabulators
	--[[
	local tab0= gui.panel(panel_width)
	local memo0=gui.memo()
	local sciLexerHash = HashFileCrc32(defaultHome.."\\".."SciLexer.dll")
	memo0:set_text(rtf.."\\cf1Heyo from tab0 :) \\line  SciLexer.dll CRC32 Hash: " .. sciLexerHash .."" ) 		
	tab0:add(memo0, "top", panel_height)
	]]
	
	-- fill the scond one with the contents of guis globalScope
	local serpent = require("serpent") -- object serializer and pretty printer
	globalScope=serpent.block(gui,{compact=true}) -- multi-line indented, no self-ref section
	sciLexerHash = HashFileCrc32(defaultHome.."\\".."SciLexer.dll")
	
	local tab1= gui.panel(panel_width)
	local memo1=gui.memo()
	memo1:set_text(globalScope.."\nSciLexer Hash: "..sciLexerHash)
	tab1:add(memo1, "top",panel_height)

	-- And add them to our main window
	local tabs= gui.tabbar(wnd)
	--tabs:add_tab("0", tab0)
	tabs:add_tab("1", tab1)
	wnd:client(tab1)
	--wnd:client(tab0)	
	-- again, add an event handler for our tabs
	tabs:on_select(function(ind)
	local visible,x,y,panel_width,panel_height = wnd:bounds()
--	memo0:size(panel_width,panel_height)
--	memo1:size(panel_width,panel_height)
	print("selected tab "..ind)
	end)

	wnd:show()
	
end

-- ##### Run Test ######

test_gui()
--_ALERT('> test sciteLua')
