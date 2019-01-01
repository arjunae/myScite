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
print(gui.to_utf8("UTF"))

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
	
	-- fill the scond one with the contents of guis globalScope
	local serpent = require("serpent") -- object serializer and pretty printer
	globalScope=serpent.block(gui,{compact=true}) -- multi-line indented, no self-ref section
	sciLexerHash = HashFileCrc32(defaultHome.."\\".."SciLexer.dll")
	
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
    
print("Hello from " .. socket._VERSION .."!")
print ("Test - DNS_Query -> www.sourceforge.net")
local addresses = assert(socket.dns.getaddrinfo("www.sourceforge.net"))
local ipv4mask = "^%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?$"

for i, alt in ipairs(addresses) do
  if alt.family == 'inet' then
    assert(type(alt.addr) == 'string')
    assert(alt.addr:find(ipv4mask))
    --assert(alt.addr == '127.0.0.1')
	 print (alt.family,alt.addr)
  end
end
print("done!")

print("HTTP-Test:")
-- load the http module
local io = require("io")
local http = require("socket.http")
local ltn12 = require("ltn12")

-- connect to server "www.example.com" and tries to retrieve
-- "/private/index.html". Fails because authentication is needed.
sURL="http://www.google.de/search?q=myScite&oq=myScite"

print ("connecting to " .. sURL)
content, status, auth = http.request(sURL)
print("response code:", status) -- status code
--print("response:", content) -- response
--[[
if content ~= nil then
print ("retrieving content from " .. sURL)
  print("Authentication Info:")
  for k, v in pairs( auth ) do
    print(k, v)
  end
end
]]

--[[
print("UDP/TCP Socket-Test:")
print("Test -  UDP socket 5088")
local u = socket.udp() assert(u:setsockname("*", 5088)) u:close()
local u = socket.udp() assert(u:setsockname("*", 0)) u:close()
print("Test -  TCP socket 5088")
local t = socket.tcp() assert(t:bind("*", 5088)) t:close()
local t = socket.tcp() assert(t:bind("*", 0)) t:close()
print("done!")
]]

print("done!")
end

-- ##### Run Test ######
--[[
for n,v in pairs(_G) do
			 print (n,v)
end
]]

_ALERT('> test sciteLua')
test_gui()
test_socket()
