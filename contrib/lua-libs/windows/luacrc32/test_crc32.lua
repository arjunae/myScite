#!/usr/bin/env lua
local _G,arg,assert,getmetatable,package,require,string,type
    = _G,arg,assert,getmetatable,package,require,string,type

local save_path = package.path
if arg[1] == nil then
	package.path = '' -- force loading crc32.so
end -- else load the crc32.lua

local C32 = require'crc32'
package.path = save_path

assert(_G.crc32==nil, 'do not pollute global env')
assert(type(C32.version)=='string')
assert(type(C32.crc32)=='function')

do
	local crc32=C32.crc32

	assert(crc32(0, 'egil') == 0x901FF815)
	assert(crc32(0, 'eg') == 0x8A8579E6)
	assert(crc32(0x8A8579E6, 'il') == 0x901FF815)

	-- test with null byte
	assert(crc32(0, string.char (1,0) ) == 0x58C223BE)


	-- test with CRC as string
	assert ( crc32('', 'egil') == string.char (0x90, 0x1F, 0xF8, 0x15))
	local c1 = crc32('', 'eg')
	assert( c1 == string.char (0x8A, 0x85, 0x79, 0xE6))
	assert ( crc32(c1, 'il') == string.char (0x90, 0x1F, 0xF8, 0x15))
end

do -- test .newcrc32()

	local crccalc = C32.newcrc32()
	--assert(type(crccalc) == 'userdata')
	local crccalc_mt = getmetatable(crccalc)
	assert(crccalc_mt.reset)


	assert(crccalc:tonumber() == 0)
	assert(crccalc:tostring() == string.char (0, 0, 0, 0))
	assert(crccalc:tohex() == '00000000')
	
	assert(crccalc:update('egil' , 'surplussparameter') == crccalc )
	assert(crccalc:tonumber() == 0x901FF815)
	assert(crccalc:tostring() == string.char (0x90, 0x1F, 0xF8, 0x15))
	assert(crccalc:tohex() == '901ff815')

	assert(crccalc:reset('surplussparameter') == crccalc )
	assert(crccalc:tonumber() == 0)
	assert(crccalc:tohex() == '00000000')

	crccalc:update'eg':update'il'
	assert(crccalc:tohex() == '901ff815')
end


--[[ -- test performance
local S = require'socket'
local now = S.gettime()

local d ={}
for i = 1, 1000 do 
	d[i] = ('%d'):format(i+1000)
end

--------------------------
local now = S.gettime()
crc = 0
for i = 1, 1000 do 
	crc = crc32(crc, d[i])
end
print( (S.gettime()- now))
print(('%8.8x'):format(crc))
print()


--------------------------
local now = S.gettime()
crc = ''
for i = 1, 1000 do 
	crc = crc32(crc, d[i])
end
print( (S.gettime()- now))
print(crc:gsub('.', function(b) return ('%2.2x'):format(b:byte()) end) )
print()

--------------------------

local now = S.gettime()
crc =  C32.newcrc32()
for i = 1, 1000 do 
	crc:update( d[i])
end
print( (S.gettime()- now))
print(crc:tohex() )

--]]

