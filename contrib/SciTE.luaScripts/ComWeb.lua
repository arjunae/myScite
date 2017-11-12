--go@ dofile $(FilePath)
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- ######### LuaCom ########
-- ## WIN Common Object Model Support for lua 
-- ####################### 
print("lua allocated mem:"..session_used_memory.."kb")

require "luacom"
--assert (loadlib ("luacom.dll","luacom_openlib")) ()

sUrl = "http://de.movies.yahoo.com"

luacom.config.abort_on_error = true 
--luacom.config.abort_on_API_error = true

-- DWebBrowserEvents2: https://msdn.microsoft.com/en-us/library/aa768283(v=vs.85).aspx
_oWeb = {} -- event handler
_oWeb.NavigateComplete2= function (self) end
_oWeb.DocumentComplete= function (self) end
_oWeb.Quit= function (self) end

cookie={} -- event connection point
tabs_name = ""
		
function test_luaCom()
-- ##  Print all links from a given URL  (Noo, we're not doin any Web-Scraping at home here :)
	--sID=luacom.CLSIDfromProgID("InternetExplorer.Application")
	--print("start Browser with CLSID "..sID)

	oWeb=luacom.GetObject("InternetExplorer.Application")

	if type(oWeb)=='nil' then oWeb=luacom.CreateObject("InternetExplorer.Application")  end
	if type(oWeb)=='nil' then
		print ("Cant initialize Browser -please try again-")
		print("cleaning up...")
		collectgarbage()
		return
	end

	event_handler = luacom.ImplInterface(_oWeb, "InternetExplorer.Application", "DWebBrowserEvents2") 
	if type(event_handler) == 'nil' then print("Error implementing Events") end
	
	res,cookie = luacom.addConnection(oWeb, event_handler)
	if res ~= 3 then print("Error implementing Events") end 

	oWeb.Height = 300
	oWeb.Width = 650
	oWeb.Visible = true
	oWeb:Navigate2(sUrl)

	print ("#> waiting for Events ...")
	
end

function _oWeb:NavigateComplete2(pObj,url)
	--print("#> Event NavigateComplete recieved! Url:"..url) 
end

function _oWeb:DocumentComplete(oWin,url) 
-- fires for every frame, so only react on root location completetition
		if oWin.locationURL  == url then
			print ("#> Event DocumentComplete recieved! ")
			print ("#> Url: "..url.." Root: "..oWin.locationURL)
			print ("#> ReadyState: "..oWin.readyState)
		   siteParser(oWin.Document)
		end
end

function siteParser(oDoc)
	-- Retrieves our IHTMLDocument. We can use all listed extensions from 1 - 8: (Mai2016)
	-- https://msdn.microsoft.com/en-us/library/ff975572(v=vs.85).aspx
	
--[[
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
]]	
	
	print(oDoc.head.innerhtml)
	print("#:::::::::::  Fin->DumpSite :::::::::::#")
end

function _oWeb:OnQuit() 

	print("#> Event Quit recieved!")
	oWin=nil
	oWeb=nil
	cookie=nil
	tabs_name=nil
	script_used_memory=(collectgarbage("count")*1024) - session_used_memory
	print("#>... Script allocated "..script_used_memory.." kb memory")
	print("#> freeing memory ...")
	collectgarbage(step,script_used_memory/1024)
	print("#> Fin")
	luacom.releaseConnection(_oWeb)
	_oWeb=nil
end

-- ######### run Test ###############

--sID=luacom.CLSIDfromProgID("SAPI.SpVoice")
--print("CLSID "..sID)

test_luaCom()

talk = assert (luacom.CreateObject ("SAPI.SpVoice"), "cannot open SAPI")
talk:Speak ("Bla. Ha HA .Haaaa... Bla!")
