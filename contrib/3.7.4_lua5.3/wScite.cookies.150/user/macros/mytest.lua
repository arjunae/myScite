
function guiTest()
-- testcases for lib GUI
require 'gui'

wnd = gui.window "test"
wnd:position(200, 200)
wnd:size(300, 140)
wnd:on_close(function() end)
wnd:show()
gui.message("testGui")
--wnd:hide()
end

guiTest()
--scite_Command('GUI_Test|guiTest|Ctrl+8')