-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function test_gui()
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
end

-- ######### LuaCom ########
events_table = {} 

function test_luaCom()
	
	require "luacom"
	print("start Browser")
	obrowser = luacom.CreateObject("InternetExplorer.Application") 
	assert(obrowser) 
	obrowser.Visible = true
	obrowser:Navigate("http://www.freedos.org")
	obrowser.Height =300
	obrowser.Width= 500
	
	print ("waiting for Events")
	event_handler = luacom.ImplInterface(events_table, "InternetExplorer.Application", "DWebBrowserEvents") 
	if event_handler == nil then  print("Error implementing Events") end 
	cookie = luacom.addConnection(obrowser, event_handler)
end

function events_table:NavigateComplete() 
	print("event NavigateComplete recieved!") 
end

function events_table:Quit() 
	print("event Quit recieved!") 
end

-- ######### run Tests ###############
test_luaCom()
test_gui()
_ALERT('> test sciteLua')
