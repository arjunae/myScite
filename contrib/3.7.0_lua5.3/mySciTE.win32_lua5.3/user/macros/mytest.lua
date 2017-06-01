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

local panel_width= 150

	-- First, we need a main window.
	wnd= gui.window "test-gui"
	wnd:position(200, 200)
	wnd:size(panel_width,150)
	-- Attach an event handler
	wnd:on_close(function() print("gui window closed") end)

	-- define a rtf colorformat 
	local rtf = [[{\rtf {\colortbl; \red30 \green60 \blue90;} ]]

	-- Now, lets create 2 Tabulators
	local tab0= gui.panel(panel_width)
	memo0=gui.memo()
	memo0:set_text(rtf.."Heyo from tab0 :) ")		
	tab0:add(memo0, "top", 80)
	
	local tab1= gui.panel(panel_width)
	memo1=gui.memo()
	memo1:set_text(rtf.."\\cf1Heyo from tab1 :p ")
	tab1:add(memo1, "top", 80)
	
	-- And add them to our main window
	local tabs= gui.tabbar(wnd)
	tabs:add_tab("0", tab0)
	tabs:add_tab("1", tab1)
	wnd:client(tab1)
	wnd:client(tab0)	
	-- again, add an event handler for our tabs
	tabs:on_select(function(ind)

		print("selected tab "..ind)
	end)
	
	wnd:show()
	--wnd:hide()

end

-- ##### Run Test ######
test_gui()
--_ALERT('> test sciteLua')
