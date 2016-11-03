
print("# --Lua: now requiring spell.dll")

local spell = require 'spell'
assert(spell, 'spell not loaded')
print("# --Lua:  spell.dll loaded")

assert(type(spell) == "function", 'spell is not a function')
print("# --Lua: okay, spell is a function - trying to call:")
s = spell('.\en_GB.aff', '.\en_GB.dic')
assert(s, 'dict not loaded')

--assert(s.spell, 'spell function does not exist')
