-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

print("Test serpent, an object serializer with prettyPrint capabilities on _G:")
local serpent = require("serpent")
--print(serpent.dump(_G)) -- full serialization
--print(serpent.line(_G)) -- single line, no self-ref section
print(serpent.block(_G,{nocode = true,maxlevel=1})) -- multi-line indented, no self-ref section

print("Test sha2 with plain lua implemented bit32.lua on SciTEUser.properties:") 
sha2= require "sha2"
local file = assert(io.open ("SciTEUser.properties", 'rb'))
local x = sha2.new256()
for b in file:lines(2^12) do
 x:add(b)
end
file:close()
print(x:close())

print("Test CRC32:") 
local C32 = require 'crc32'
local crc32=C32.crc32
print ('CyclicRedundancyCheck==', crc32(0, 'CyclicRedundancyCheck')) 

--print_registryidx()
print ("lua Version==",_VERSION)
-- Test Scite->lua global Variable namespace
print("Value of IDM_NEXTMSG==", IDM_NEXTMSG)

-- test some scite pane api functions
line=0
marker_define(0,0)

editor:GotoLine(line+10)
editor:MarkerAdd(line,0)
editor:MarkerDelete(line,0)
