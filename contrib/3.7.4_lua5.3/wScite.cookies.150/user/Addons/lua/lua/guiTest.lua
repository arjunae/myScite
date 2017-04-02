
function guiTest()
-- testcases for lib GUI
require 'gui'
gui.message("testGui_msg")
wnd = gui.window "testGui_wnd"
wnd:position(200, 200)
wnd:size(300, 140)
wnd:on_close(function() end)
wnd:show()

end

scite_Command('guiTest|guiTest|Ctrl+7')