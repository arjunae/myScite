Lua module for CRC-32 calculation implemented in C. 

It is only tested with Lua 5.1.

Also included is a pure Lua implementation of the same API, using
https://github.com/davidm/lua-digest-crc32lua.


# Module API
`local crc32 = require 'crc32'`

* **crc32.crc32** = function (crc_in, data)
	* **crc_in** is input CRC. It can be either a Lua number, or a string.
	If string is used, it should be 4 bytes in big endian order. 
	If string shorter than 4 bytes, then CRC is left padded with zeros.
	* **data** is the input data to apply to CRC, as a Lua string.
	* **returns** updated CRC. If crc_in is number, then returns number. 
	If crc_in is string, then return as string, 4 bytes in big endian order.
* **crc32.newcrc32** = function ()
	* **returns** a stateful CRC-32 calculator object (userdata). 
	It is useful for streaming CRC calculation, as it keep the current
	CRC as a native uint32_t between calls, reducing conversion overhead. 
* **crc32.version** = string

## crc32.newcrc32 API
`local c = crc32.newcrc32()`

* **c.update** = function (self, data)
	* **data** is the input data to apply to CRC, as a Lua string.
	* **returns** self
* **c.reset** = function (self) 
	* Resets the current CRC to 0. 
	* **returns** self
* **c.tonumber** = function (self)
	* **returns** current CRC as Lua number
* **c.tostring** = function (self)
	* **returns** current CRC as string, 4 bytes in big endian order.
* **c.tohex** = function (self)
	* **returns** current CRC as 8 character hex encoded string.
