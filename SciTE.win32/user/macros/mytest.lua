-- go@ dofile *
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

	-- Now, lets create 2 Tabulators
	local tab0= gui.panel(panel_width)
	memo=gui.memo()
	tab0:add(memo, "top", 25)
	local tab1= gui.panel(panel_width)
	memo=gui.memo()
	tab1:add(memo, "bottom", 25)
	
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
