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

-- ######### LuaCom ########

require "luacom"
oweb={} -- OLE object
_oweb = {} -- its events

function test_luaCom()
--testcases for lib luacom	
	print("start Browser")
	oweb = luacom.CreateObject("InternetExplorer.Application") 
	assert(oweb) 
	oweb:Navigate("http://www.freedos.org")
	oweb.Height =300
	oweb.Width= 500
	oweb.Visible = true

	print ("waiting for Events")
	-- DWebBrowserEvents2: https://msdn.microsoft.com/en-us/library/aa768283(v=vs.85).aspx
	event_handler = luacom.ImplInterface(_oweb, "InternetExplorer.Application", "DWebBrowserEvents2") 
	if event_handler == nil then  print("Error implementing Events") end 
	cookie = luacom.addConnection(oweb, event_handler)
end

function _oweb:NavigateComplete2(a,url) 
--	print("event NavigateComplete recieved! Url:"..url) 
end

function _oweb:DocumentComplete(a,url) 
-- fires for every frame, so only react on root location complete
	  if oweb.locationURL  == url then
			print("event DocumentComplete recieved! ")
			print("Url: "..url.." Root: "..oweb.locationURL)
			content=oweb.Document.head.innerhtml
			gui.message(content)
		
	--print (content)
		end
end

function _oweb:OnQuit() 
	print("event Quit recieved!") 
	oweb=nil
	_oweb=nil
	collectgarbage()
end

-- ######### run Tests ###############

test_luaCom()
test_gui()
_ALERT('> test sciteLua')
