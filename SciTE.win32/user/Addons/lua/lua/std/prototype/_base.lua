--[[
 Prototype Oriented Programming for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2000-2018 std.prototype authors
]]

local _ENV = require 'std.normalize' {
   nonempty = next,
   sub = string.sub,
}

local argscheck
do
   local ok, typecheck = pcall(require, 'typecheck')
   if ok then
      argscheck = typecheck.argscheck
   else
      argscheck = function(decl, fn)
         return fn
      end
   end
end


return {
   Module = function(t)
      return setmetatable(t, {
         _type = 'Module',
         __call = function(self, ...)
            return self.prototype(...)
         end,
      })
   end,

   argscheck = argscheck,

   mapfields = function(obj, src, map)
      local mt = getmetatable(obj) or {}

      -- Map key pairs.
      -- Copy all pairs when `map == nil`, but discard unmapped src keys
      -- when map is provided(i.e. if `map == {}`, copy nothing).
      if map == nil or nonempty(map) then
         map = map or {}
         for k, v in next, src do
            local key, dst = map[k] or k, obj
            local kind = type(key)
            if kind == 'string' and sub(key, 1, 1) == '_' then
               mt[key] = v
            elseif nonempty(map) and kind == 'number' and len(dst) + 1 < key then
               -- When map is given, but has fewer entries than src, stop copying
               -- fields when map is exhausted.
               break
            else
               dst[key] = v
            end
         end
      end

      -- Only set non-empty metatable.
      if nonempty(mt) then
         setmetatable(obj, mt)
      end
      return obj
   end,
}
