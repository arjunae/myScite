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
--test_socket()

local ok, err = pcall(function()
    require("toolbar")  -- "toolbar.dll" muss also als "toolbar" geladen werden
end)

if ok then
    print("Toolbar erfolgreich geladen.")
else
    print("Fehler beim Laden der Toolbar:", err)
end
