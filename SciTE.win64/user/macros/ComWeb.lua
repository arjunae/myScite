--go@ dofile $(FilePath)
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ######### LuaCom ########
-- ## WIN Common Object Model Support for lua 
-- ####################### 
print("lua allocated mem:"..session_used_memory.."kb")

require "luacom"
--assert (loadlib ("luacom.dll","luacom_openlib")) ()

sUrl = "http://de.movies.yahoo.com"

--luacom.config.abort_on_error = true 
--luacom.config.abort_on_API_error = true

_oWeb = {} -- it's events
cookie={} -- event connection point
tabs_title = ""

function test_luaCom()
-- ##  Print all links from a given URL  (Noo, we're not doin any Web-Scraping at home here :)
	--sID=luacom.CLSIDfromProgID("InternetExplorer.Application")
	--print("start Browser with CLSID "..sID)

	oWeb=luacom.CreateObject("InternetExplorer.Application")
	if type(oWeb)==nil then
		print ("clean_up")
		collectgarbage()
	end
	
	-- DWebBrowserEvents2: https://msdn.microsoft.com/en-us/library/aa768283(v=vs.85).aspx
	event_handler = luacom.ImplInterface(_oWeb, "InternetExplorer.Application", "DWebBrowserEvents2") 
	if type(event_handler) == nil then print("Error implementing Events") end
	
	res,cookie = luacom.addConnection(oWeb, event_handler)
	if res ~= 3 then print("Error implementing Events") end 

	oWeb.Height = 300
	oWeb.Width = 650
	oWeb.Visible = true
	oWeb:Navigate(sUrl)
		
	print ("waiting for Events")
end

function _oWeb:NavigateComplete2(a,url)
	--print("event NavigateComplete recieved! Url:"..url) 
end

function _oWeb:DocumentComplete(oWin,url) 
-- fires for every frame, so only react on root location completetition
		if oWin.locationURL  == url then
			print("event DocumentComplete recieved! ")
			print("Url: "..url.." Root: "..oWin.locationURL)
		   siteParser(oWin.Document)
		end
end

function siteParser(oDoc)
	-- Retrieves our IHTMLDocument. We can use all listed extensions from 1 - 8: (Mai2016)
	-- https://msdn.microsoft.com/en-us/library/ff975572(v=vs.85).aspx
	

	-- Now print out all links found within the Site
	eTmp=oDoc.body:getElementsByTagName("a")
	linksEnum=luacom.GetEnumerator(eTmp)
	link=linksEnum:Next()
	-- todo: copy data into a lua buffer and do the output later.
	
	while link do
		print("found webblink: "..link.href) -- toDo parse nicely into myScite calltips :) 
		link=linksEnum:Next()
	end
	link=nil
	linksEnum=nil
	eTmp=nil
	oDoc=nil
	
	
	--print(oDoc.head.innerhtml)
	print("Fin->DumpSiteLinks")
end

function _oWeb:OnQuit() 

	print("event Quit recieved!")
	--luacom.releaseConnection(cookie,oWeb)	
	oWin=nil
	oWeb=nil
	_oWeb=nil
	cookie=nil
	tabs_title=nil
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

talk = assert (luacom.CreateObject ("SAPI.SpVoice"), "cannot open SAPI")
talk:Speak ("Bla. Ha HA .Haaaa... Bla!")
