
function guiTest()
-- testcases for lib GUI
require 'gui'

wnd = gui.window "test"
wnd:position(200, 200)
wnd:size(300, 140)
wnd:on_close(function() end)
wnd:show()
--gui.message("testGui")
--wnd:hide()

function marker_define(idx,typ)
	editor:MarkerDefine(idx,typ)
end

line=0
marker_define(0,0)
--editor:GotoLine(line)
--editor:MarkerAdd(line,0)
end

guiTest()
--scite_Command('GUI_Test|guiTest|Ctrl+8')
