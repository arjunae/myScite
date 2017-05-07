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
luacom.config.abort_on_error = true 
luacom.config.abort_on_API_error = true 

tImplement={}
oWeb={} -- OLE object
_oWeb = {} -- its events
	
function test_luaCom()
--testcases for lib luacom	
	sID=luacom.CLSIDfromProgID("InternetExplorer.Application")
	print("start Browser with CLSID "..sID)
	oWeb = luacom.CreateObject("InternetExplorer.Application") 
	assert(oWeb) 
	oWeb:Navigate("http://www.freedos.org")
	oWeb.Height =300
	oWeb.Width= 500
	oWeb.Visible = true

	print ("waiting for Events")
	-- DWebBrowserEvents2: https://msdn.microsoft.com/en-us/library/aa768283(v=vs.85).aspx
	event_handler = luacom.ImplInterface(_oWeb, "InternetExplorer.Application", "DWebBrowserEvents2") 
	if event_handler == nil then  print("Error implementing Events") end 
	cookie = luacom.addConnection(oWeb, event_handler)

end

function _oWeb:NavigateComplete2(a,url) 
--	print("event NavigateComplete recieved! Url:"..url) 
end

function _oWeb:DocumentComplete(oWin,url) 
-- fires for every frame, so only react on root location complete
	  if oWeb.locationURL  == url then
			print("event DocumentComplete recieved! ")
			print("Url: "..url.." Root: "..oWeb.locationURL)
		   siteParser(oWin)
			print("Fin")
		end
end

function siteParser(oWin)
	-- ihtmlWindow contains our ihtmlDocument	
	oDoc=oWin.Document
	content=oDoc.head.innerhtml
	-- using get / set prefix to access properties 
	title=oDoc:gettitle()
	--gui.message(title)
	oDoc:settitle("myTitle")
		print(content)
	oDoc=nil
end

function _oWeb:OnQuit() 
	print("event Quit recieved!") 
	oWeb=nil
	_oWeb=nil
	collectgarbage()
end

-- ######### run Tests ###############
test_luaCom()
test_gui()
_ALERT('> test sciteLua')
