

print("# --Lua: now requiring hunspell.dll")

local hunspell = require 'hunspell'
assert(hunspell, 'hunspell not loaded')
print("# --Lua: hunspell.dll loaded")

assert(type(hunspell) == "table", 'hunspell is not a table')

print("# --Lua: now calling hunspell.init")
s = hunspell.init('.\en_GB.aff', '.\en_GB.dic')
assert(s, 'dict not loaded')
