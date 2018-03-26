-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local defaultHome= props["SciteDefaultHome"]

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print("-> go1 sha1 lol") 
local sha1 = require "sha1"
local file,err = assert(io.open (defaultHome.."\\".."SciTEUser.properties", 'rb'))
local content =""
ckTho=true
c0=0
while ckTho==true do
	local GoGo = file:read(6615)
	if not GoGo then break end
	c0=c0..GoGo
end	
local cryptSHA1= sha1(c0)

file:close()
print(cryptSHA1,"~~ Crypto SHA1 Hash :")

print("-> Test CRC32:") 
--[[
crc32.crc32 = function (crc_in, data)
crc_in -> 4 Byte input CRC, automatically padded.
data->  input data to apply to CRC, as a Lua string.
returns -> updated CRC. 
]]
	
local C32 = require 'crc32'
local crc32=C32.crc32
--print ('CyclicRedundancyCheck==', crc32(0, 'CyclicRedundancyCheck')) 

local crccalc = C32.newcrc32()
local crccalc_mt = getmetatable(crccalc)
local file = assert(io.open (defaultHome.."\\".."SciLexer.dll", 'rb'))
while true do
	local bytes = file:read(4096)
	if not bytes then break end
	crccalc:update(bytes)
end	

file:close()
print("SciLexer CRC32 Hash:",crccalc:tohex())

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print("-> Test SciTE lua wrapper") 
--print_registryidx()
print ("lua Version String ==",_VERSION)
-- Test Scite->lua global Variable namespace
print("Value of IDM_NEXTMSG ==", IDM_NEXTMSG)