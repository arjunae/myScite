--go@ dofile $(FilePath)
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ######### LuaCom ########
-- ## WIN Common Object Model Support for lua 
-- ####################### 
print("lua allocated mem:"..session_used_memory)

require "luacom"

sUrl = "http://www.yahoo.de"

luacom.config.abort_on_error = true 
luacom.config.abort_on_API_error = true 

oWeb = {} -- OLE object
_oWeb = {} -- it's events

function test_luaCom()
-- ##  Print all links from a given URL  (Noo, we're not doin any Web-Scraping at home here :)
	sID=luacom.CLSIDfromProgID("InternetExplorer.Application")
	print("start Browser with CLSID "..sID)

	oWeb=assert(luacom.CreateObject("InternetExplorer.Application")) 
	if not oWeb then
		print ("clean_up")
		collectgarbage()
	end
	
	oWeb:Navigate(sUrl)
	oWeb.Height = 300
	oWeb.Width = 650
	oWeb.Visible = true
	
	print ("waiting for Events")
	-- DWebBrowserEvents2: https://msdn.microsoft.com/en-us/library/aa768283(v=vs.85).aspx
	event_handler = luacom.ImplInterface(_oWeb, "InternetExplorer.Application", "DWebBrowserEvents2") 
	if event_handler == nil then print("Error implementing Events") end 
	cookie = luacom.addConnection(oWeb, event_handler)
	
	event_handler=nil
	cookie=nil
end

function _oWeb:NavigateComplete2(a,url)
	--print("event NavigateComplete recieved! Url:"..url) 
end

function _oWeb:DocumentComplete(oWin,url) 
-- fires for every frame, so only react on root location completetition
		if oWeb.locationURL  == url then
			print("event DocumentComplete recieved! ")
			print("Url: "..url.." Root: "..oWeb.locationURL)
		   siteParser(oWin)
		end
end

function siteParser(oWin)
	-- Retrieves our IHTMLDocument. We can use all listed extensions from 1 - 8: (Mai2016)
	-- https://msdn.microsoft.com/en-us/library/ff975572(v=vs.85).aspx
	
	oDoc=oWin.Document
	
	-- Now print out all links found within the Site
	eTmp=oDoc.body:getElementsByTagName("a")
	linksEnum=luacom.GetEnumerator(eTmp)
	link=linksEnum:Next()
	while link do
		print("found webblink: "..link.href) -- toDo parse nicely into myScite calltips :) 
		link=linksEnum:Next()
	end
	
	--	content=oDoc.head.innerhtml
	--	print(content)
	link=nil
	linksEnum=nil
	eTmp=nil
	oDoc=nil
	
	print("Fin")
end

function _oWeb:OnQuit() 
	print("event Quit recieved!") 
	oWin=nil
	oWeb=nil
	_oWeb=nil
	script_used_memory=(collectgarbage("count")*1024) - session_used_memory
	print("... Script allocated "..script_used_memory.." kb memory")
	print("freeing memory ...")
	collectgarbage(step,script_used_memory/1024)
	print("Fin")
end

-- ######### run Test ###############

test_luaCom()
--	sID=luacom.CLSIDfromProgID("SAPI.SpVoice")
--	print("CLSID "..sID)
