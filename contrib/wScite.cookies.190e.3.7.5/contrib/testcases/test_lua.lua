-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.

local defaultHome= props["SciteDefaultHome"]
print("-> Test go1 SHA1") 
local sha1 = require "sha1"
local file,err = assert(io.open (defaultHome.."\\".."SciTEUser.properties", 'rb'))
local content =""
ckTho=true
c0=0
while ckTho==true do
	local SoSo = file:read(6615)
	if not SoSo then break end
	c0=c0..SoSo
end	
local cryptSHA1= sha1(c0)
file:close()
print("~~ SciTEUser.properties SHA1 Hash: "..cryptSHA1)
print("-> Test MD5:") 
local md5 = require 'md5'
local file = assert(io.open (defaultHome.."\\".."SciTEUser.properties", 'rb'))
--local file = assert(io.open (defaultHome.."\\".."SciLexer.dll", 'rb'))
local content=file:read("*a")
file:close()
print("SciTEUser.properties MD5 Hash: "..md5.sumhexa(content))

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
-- go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
print ("->Test: bk-trees (Levenshtein)")

word = "bercleve"
distance =3

bktree = require "bk-tree"

words = {
	"bark", 
	"car", 
	"dog", 
	"weird",
	"really",
	"beauty",
	"vehicle",
	"perceive",
	"presence",
	"original",
	"beautiful", 
	"definitely", 
	"immediately", 
	"accidentally"
}

tree = bktree:new("book")
--tree:debug()
local x = os.clock()

--print("Available words: " .. #words)
for k, word in pairs(words) do
--	print(" - " .. word)
	tree:insert(word)
end

local t = os.clock() - x
print("elapsed time: " .. t .. " s")
print(" - time per word: " .. (t/#words)+1 .. " s")

result = tree:query_sorted(word, tonumber(distance))
if result then
	print("searchWord:\n "..word)
	print("candidates: ")
	for k, v in pairs(result) do
	    print (" "..v.str, v.distance)
	end
else
	print("no results!")
end

print("-> Test SciTE lua wrapper") 
print ("lua Version String ==",_VERSION)
-- Test Scite->lua global Variable namespace
print("Value of IDM_NEXTMSG ==", IDM_NEXTMSG)
