--[[
 Prototype Oriented Programming for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2000-2018 std.prototype authors
]]
--[[--
 Module table.

 Lazy loading of submodules, and metadata for the Prototype package.

 @module std.prototype
]]


local _ENV = require 'std.normalize' {}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


return setmetatable({
   --- Module table.
   -- @table prototype
   -- @field version   Release version string
}, {
   --- Metamethods
   -- @section Metamethods

   --- Lazy loading of prototype modules.
   -- Don't load everything on initial startup, wait until first attempt
   -- to access a submodule, and then load it on demand.
   -- @function __index
   -- @string name submodule name
   -- @treturn table|nil the submodule that was loaded to satisfy the missing
   --    `name`, otherwise `nil` if nothing was found
   -- @usage
   --   local prototype = require 'prototype'
   --   local Object = prototype.object.prototype
   __index = function(self, name)
      local ok, t = pcall(require, 'std.prototype.' .. name)
      if ok then
         rawset(self, name, t)
         return t
      end
   end,
})
