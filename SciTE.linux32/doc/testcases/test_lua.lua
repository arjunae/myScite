-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local defaultHome= props["SciteDefaultHome"]

function marker_define(idx,typ)
-- Test scite object namespace
	editor:MarkerDefine(idx,typ)
end

function print_registryidx()
-- Print scites registryindex namespace
	for k, v in pairs( debug.getregistry () ) do
		print(k, v)
	end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~

print("-> Test serpent, an object serializer with prettyPrint capabilities on _G:")
local serpent = require("serpent")
--print(serpent.dump(_G)) -- full serialization
--print(serpent.line(_G)) -- single line, no self-ref section
print(serpent.block(_G,{nocode = true,maxlevel=1})) -- multi-line indented, no self-ref section

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print("-> Test sha2 with plain lua implemented bit32.lua")  -- native CVersion >= lua5.2
sha2= require "sha2"
local file = assert(io.open (defaultHome.."\\".."SciTEUser.properties", 'rb'))
local sha256 = sha2.new256()
while true do
	local bytes = file:read(4096)
	if not bytes then break end
	sha256:add(bytes)
end	

file:close()
print("SciTEUser.properties SHA2-256 Hash:", sha256:close())

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print("-> Test MD5:") 

local md5 = require 'md5'
local m = md5.new()
local file = assert(io.open (defaultHome.."\\".."SciTEUser.properties", 'rb'))
while true do
	local bytes = file:read(4096)
	if not bytes then break end
	m:update(bytes)
end	
	file:close()
print("SciTEUser.properties MD5 Hash:	", md5.tohex(m:finish()))

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
assert(crccalc_mt.reset) -- reset to zero
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

line=0
marker_define(0,0)
editor:GotoLine(line+10)
editor:MarkerAdd(line,0)
editor:MarkerDelete(line,0)
