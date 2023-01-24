local require,setmetatable,string,table,type
    = require,setmetatable,string,table,type
--[[ A pure Lua implementation of the crc32.so API. Uses 
-- https://github.com/davidm/lua-digest-crc32lua/blob/master/lmod/digest/crc32lua.lua
-- for the CRC-32 calcuation
]]

local crc32lua = require 'crc32lua'
local bit = require'bit32'
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift

local crc32_string =  crc32lua.crc32_string

local crc_mt = {
	update = function (self, data)
		self[1] =  crc32_string(data, self[1]  )
		return self
	end, 
	reset = function (self)
		self[1] = 0
		return self
	end, 
	tonumber = function (self)
		return self[1] 
	end, 
	tostring = function (self)
		local crc_out = self[1] 
		local crcout_bytes = {}
		for i =  4, 1,-1  do
			crcout_bytes[i] = string.char(band( crc_out , 0xff))
			crc_out = rshift(crc_out, 8)
		end
		return table.concat(crcout_bytes)
	end, 
	tohex = function (self)
		return ('%8.8x'):format(self[1] )
	end, 
}
crc_mt.__index = crc_mt


return {
	crc32 = function (crc, data)
	
		if type(crc) == 'string' then
			local crc_len=#crc
			if crc_len>4 then crc_len = 4 end
			local crc_in = 0;
			for i =  1, crc_len do
				crc_in = lshift(crc_in, 8)
				crc_in = bor(crc_in, crc:byte(i))
			end
			
			local crc_out = crc32_string(data, crc_in )
			local crcout_bytes = {}
			for i =  4, 1,-1  do
				crcout_bytes[i] = string.char(band( crc_out , 0xff))
				crc_out = rshift(crc_out, 8)
			end
			return table.concat(crcout_bytes)
		end
		return crc32_string(data, crc )
	end,
	
	newcrc32 = function ()
		return setmetatable({0}, crc_mt)
	end,
	version='1.0',
}
