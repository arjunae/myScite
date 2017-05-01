-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ######### LuaGui ########
require 'gui'

function test_gui()
-- testcases for lib GUI

	wnd = gui.window "test-gui"
	wnd:position(200, 200)
	wnd:size(300, 140)
	wnd:on_close(function() end)

	memo=gui.memo()
	wnd:add(memo, "top", 25)
	wnd:show()

	--wnd:hide()
end

-- ######### run Tests ###############
test_gui()
_ALERT('> test sciteLua')
