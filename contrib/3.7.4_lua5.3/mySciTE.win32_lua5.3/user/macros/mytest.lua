-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function guiTest()
-- testcases for lib GUI
	require 'gui'

	wnd = gui.window "test-gui"
	wnd:position(200, 200)
	wnd:size(300, 140)
	wnd:on_close(function() end)

	memo=gui.memo()
	wnd:add(memo, "top", 25)
	wnd:show()

	--gui.message("testGui")
	--wnd:hide()

--marker--
-- Test SCFIND_REGEXP
local marker = "--test--.* "
local flag = SCFIND_REGEXP
local start,ende = editor:findtext(marker, flag, 0)
_ALERT('> test sciteLua')
end

guiTest()
