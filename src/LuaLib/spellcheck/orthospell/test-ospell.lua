
print("# --Lua: now requiring hunspell.dll")

local hunspell = require 'hunspell'
assert(hunspell, 'hunspell not loaded')
print("# --Lua: hunspell.dll loaded")

assert(type(hunspell) == "table", 'hunspell is not a table')

print("# --Lua: now calling hunspell.init")
hunspell.init('..\\dict\\default.aff', '..\\dict\\default.dic')


print("# --Lua: now calling hunspell.suggest(\'FireFly\'))");

local sug = hunspell.suggest("\'FireFly\'");
	 print ("found: "..#sug.." suggetions")
    if #sug > 0 then
		print("hunspell.suggest:"..table.concat(sug, " "))   
    end
	 
print("# --Lua: Closing Hunspell");
hunspell.close();
