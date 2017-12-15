--go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print("Hello from scitelua!")

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
	wnd:size(550,500)
	local visible,x,y,panel_width,panel_height = wnd:bounds()
	-- Attach an event handler
	wnd:on_close(function() print("gui window closed") end)
	
	-- define a rtf colorformat 
	local rtf = [[{\rtf {\colortbl; \red30 \green60 \blue90;} ]]

	-- Now, lets create 2 Tabulators
	local tab0= gui.panel(panel_width)
	local memo0=gui.memo()
	memo0:set_text(rtf.."\\cf1Heyo from tab0 :) ")		
	tab0:add(memo0, "top", panel_height)

	-- fill the scond one with the contents of guis globalScope
	local serpent = require("serpent") -- object serializer and pretty printer
	local globalScope=serpent.block(gui,{nocode = true}) -- multi-line indented, no self-ref section
	
	local tab1= gui.panel(panel_width)
	local memo1=gui.memo()
	memo1:set_text(globalScope)
	tab1:add(memo1, "top",panel_height)

	-- And add them to our main window
	local tabs= gui.tabbar(wnd)
	tabs:add_tab("0", tab0)
	tabs:add_tab("1", tab1)
	wnd:client(tab1)
	wnd:client(tab0)	
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