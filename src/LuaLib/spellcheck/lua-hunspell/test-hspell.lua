local spell = require 'spell'

assert(spell, 'spell not loaded')
assert(type(spell) == "function", 'spell is not a function')

s = spell('..//dict//default.aff', '..//dict//default.dic')
assert(s, 'dict not loaded')

local okword = 'friendliness'
local badword = 'friendlines'

assert(s.spell, 'spell function does not exist')
assert(s:spell(okword), 'spell("'..okword..'") should return true')
assert(not s:spell(badword), 'spell("'..badword..'") should return false')

assert(s.suggest, 'suggest function does not exist')
local t = s:suggest(badword)
local found = false
for _,v in ipairs(t) do
	if v == okword then
		found = true
		break
	end
end
assert(found, badword .. ' -> '..okword..' suggestion not found')

assert(s.analyze, 'analyze function does not exist')
local t = s:analyze(okword)
assert(type(t) == "table", 'analyze() does not return a table: '..type(t))
print('Analysis of '..okword)
for _,v in ipairs(t) do
	print('>', v)
end


local root = s:stem(okword)
assert(type(root) == "table", 'stem() does not return a table: '..type(root))
print('Roots of '..okword)
for _,v in ipairs(root) do
	print('>', v)
end

print(unpack(s:analyze('cars')))
local gen = s:generate('word', 'cars')
print(#gen, unpack(gen))
local gen2 = s:generate('word', {'fl:S'})
print(#gen2, unpack(gen2))


print('OK')
