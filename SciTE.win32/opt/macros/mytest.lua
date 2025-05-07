-- go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local defaultHome= props["SciteDefaultHome"]
print("Hello from scitelua!")

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ####### LuaCrc32 ######
-- ## crc32 Hash Library
-- ##################
function HashFileCrc32(filename)
	--[[
	crc32.crc32 = function (crc_in, data)
	crc_in -> 4 Byte input CRC, automatically padded.
	data->  input data to apply to CRC, as a Lua string.
	returns -> updated CRC. 
	]]

	C32 = require 'crc32'
	crc32=C32.crc32
	--print ('CyclicRedundancyCheck==', crc32(0, 'CyclicRedundancyCheck')) 

	crccalc = C32.newcrc32()
	crccalc_mt = getmetatable(crccalc)
	assert(crccalc_mt.reset) -- reset to zero
	file = assert(io.open (filename, 'rb'))
	while true do -- read binary file in 4k chunks
		bytes = file:read(4096)
		if not bytes then break end
		crccalc:update(bytes)
	end	

	file:close()
	file=nil
	--print("SciLexer CRC32 Hash:",crccalc:tohex())
	return(crccalc:tohex())
end

-- ####### LuaGui ######
-- ## MsWin widget Library
-- ##################
function test_gui()
require 'gui'

-- testcases for lib GUI
	print("[Test: gui.to_utf8] "..gui.to_utf8("UTF"))
	print("[Test: gui window]")
	-- First, we need a main window.
	local wnd= gui.window "test-gui"
	wnd:position(200, 200)
	wnd:size(320,500)
	local visible,x,y,panel_width,panel_height = wnd:bounds()
	-- Attach an event handler
	wnd:on_close(function() print("gui window closed") end)
	
	-- define a rtf colorformat 
	local rtf = [[{\rtf {\colortbl; \red30 \green60 \blue90;} ]]

	-- Now, lets create 2 Tabulators
	--[[
	local tab0= gui.panel(panel_width)
	local memo0=gui.memo()
	local sciLexerHash = HashFileCrc32(defaultHome.."\\".."SciLexer.dll")
	memo0:set_text(rtf.."\\cf1Heyo from tab0 :) \\line  SciLexer.dll CRC32 Hash: " .. sciLexerHash .."" ) 		
	tab0:add(memo0, "top", panel_height)
	]]
	
	-- fill with the contents of guis globalScope
	local inspect = require("inspect")
	globalScope=inspect(gui);
	print("[Test inspect.lua] (gui function table in tab1)")
	sciLexerHash = HashFileCrc32(defaultHome.."\\".."SciLexer.dll")
	print("[Test crc32] sciLexer's Hash="..sciLexerHash)
	
	local tab1= gui.panel(panel_width)
	local memo1=gui.memo()
	memo1:set_text(globalScope.."\nSciLexer Hash: "..sciLexerHash)
	tab1:add(memo1, "top",panel_height)

	-- And add them to our main window
	local tabs= gui.tabbar(wnd)
	--tabs:add_tab("0", tab0)
	tabs:add_tab("1", tab1)
	wnd:client(tab1)
	--wnd:client(tab0)	
	-- again, add an event handler for our tabs
	tabs:on_select(function(ind)
	local visible,x,y,panel_width,panel_height = wnd:bounds()
--	memo0:size(panel_width,panel_height)
--	memo1:size(panel_width,panel_height)
	print("selected tab "..ind)
	end)

	wnd:show()
	
end

-- ####### LuaSocket ######
-- ## Network Connectivity Library
-- ##################

function test_socket()
local socket = require "socket"
-- library provides 
-- "_VERSION", "_DEBUG", "gettime", "newtry", "protect", "select", "sink", "skip", "sleep", "source", "try" "auxiliar", "except", "timeout", "buffer","inet"
-- socket.dns: "dns.toip", "dns.tohostname", "dns.gethostname"
-- socket.tcp: "tcp.accept", "tcp.bind", "tcp.close", "tcp.connect", "tcp.getpeername","tcp.getstats", "tcp.recieve", "tcp.send", "tcp.setoption", "tcp.setstats", "tcp.settimeout", "tcp.shutdown"
-- socket.udp: "udp.close", "udp.getpeername", "udp.getsockname", "udp.receive", "udp.receivefrom", "udp.send", "udp.sendto", "udp.setpeername", "udp.setsockname", "udp.setoption", "udp.settimeout" 
-- socket.lua layer provides "connect4", "connect6", "bind"
    
--print("Hello from " .. socket._VERSION .."!")

--[[
print ("[Test LuaSocket] (UDP/TCP)"
print("Test -  UDP socket 5088")
local u = socket.udp() assert(u:setsockname("*", 5088)) u:close()
local u = socket.udp() assert(u:setsockname("*", 0)) u:close()
print("Test -  TCP socket 5088")
local t = socket.tcp() assert(t:bind("*", 5088)) t:close()
local t = socket.tcp() assert(t:bind("*", 0)) t:close()
print("done!")
]]

print ("[Test LuaSocket] (DNS):")
local addresses = assert(socket.dns.getaddrinfo("www.sourceforge.net"))
local ipv4mask = "^%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?$"
for i, alt in ipairs(addresses) do
  if alt.family == 'inet' then
    assert(type(alt.addr) == 'string')
    assert(alt.addr:find(ipv4mask))
    --assert(alt.addr == '127.0.0.1')
	 print ("www.sourceforge.net: ".. alt.family,alt.addr)
  end
end

-- Using ssl.dll directly 
print("[Test socket+SSL]")
require("socket")
local https = require("ssl.https")
local body, code, headers, status= https.request("https://www.google.com/search?q=myscite")
print("https://www.google.com/search?q=myscite ["..status.."]")
--print(body)

--[[
-- Using httpclient.lua from https://github.com/lusis/lua-httpclient
print("[Test httpclient] (GET):")
local inspect = require("inspect")
hc=require("httpclient").new()
local params = {q = "mySciTE"}
local opts = {params = params}
local res = hc:get("http://www.google.de/search",opts)
print("response code:", res.code) -- status code
print(inspect(res.body))
--]]

end

-- ##### Run Test ######
--[[
-- print globalScope
for n,v in pairs(_G) do
			 print (n,v)
end
]]

_ALERT('> Test SciTE Lua Modules')
--test_gui()
--test_socket()
local list = { "SciTEBase::GetMenuCommandAsInt(std::string commandName)int ", "SciTEBuffers::GetMenuCommandAsInt(std::string commandName)int " }

local  apiCache = {}
local DEBUG=1

funcName="GetMenuCommandAsInt"
local tipCount=0
for _, entry in ipairs(list ) do
  -- keep the original line around
  local fullLine = entry

  -- gfuncName(h at the very start (i.e. no namespace)
  local prefixMatch = entry:match("^(.-)%(")
  local extractedName

  if prefixMatch == funcName then
    extractedName = prefixMatch
  else
    -- Namespace::Member(c)h
    extractedName = entry:match("::([%w_]+)%(")
  end

  -- now check whether what we extracted is our target function
  if extractedName == funcName then
    print("? matched:", fullLine)
    -- extract the argument list inside the parentheses
    local args = fullLine:match("%((.-)%)") or ""
    
  
       if args ~= "" then
        tipCount = tipCount + 1
        if tipCount == 1 then
          strCalltip = args
        else
          strCalltip = strCalltip .. "\n" .. args
        end
      end
    end
  end  -- Ende der for-Schleife

  -- Calltip nur anzeigen, wenn wir etwas gesammelt haben
  if tipCount > 0 then
    editor:CallTipShow(1, strCalltip)
   else
  end
  
	
	
	
	
for _, entry in ipairs(list) do
--print(entry)
--print(entry:match("::([%w_]+)%("))
--entry=entry:match("::([%w_]+)%(")

--print(entry:match("^" .. funcName .. "%f[%A]")) --Namespace member wo Namespace end
	end
