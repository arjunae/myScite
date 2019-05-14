--[[
 Functional programming for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2002-2018 std.functional authors
]]
--[[--
 Purely to break internal dependency cycles without introducing
 multiple copies of base functions used in other modules.

 @module std.functional._base
]]

local _ENV = require 'std.normalize' {
   'string.format',
   'table.concat',
   'table.keys',
   'table.sort',
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



--[[ ================= ]]--
--[[ Shared Functions. ]]--
--[[ ================= ]]--


local function shallow_copy(t)
   local r = {}
   for k, v in next, t do
      r[k] = v
   end
   return r
end


local function toqstring(x)
   if type(x) ~= 'string' then
      return tostring(x)
   end
   return format('%q', x)
end


local function keycmp(a, b)
   if type(a) == 'number' then
      return type(b) ~= 'number' or a < b
   else
      return type(b) ~= 'number' and tostring(a) < tostring(b)
   end
end


local function sortedkeys(t, cmp)
   local r = keys(t)
   sort(r, cmp)
   return r
end


local function serialize(x, roots)
   roots = roots or {}

   local function stop_roots(x)
      return roots[x] or serialize(x, shallow_copy(roots))
   end

   if type(x) ~= 'table' or getmetamethod(x, '__tostring') then
      return toqstring(x)

   else
      local buf = {'{'} -- pre-buffer table open
      roots[x] = toqstring(x) -- recursion protection

      local kp -- previous key
      for _, k in ipairs(sortedkeys(x, keycmp)) do
         if kp ~= nil then
            buf[#buf + 1] = ','
         end
         buf[#buf + 1] = stop_roots(kp) .. '=' .. stop_roots(x[k])
         kp = k
      end
      buf[#buf + 1] = '}' -- buffer << table close

      return concat(buf) -- stringify buffer
   end
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


return {
   argscheck = argscheck,
   serialize = serialize,
   toqstring = toqstring,
}
