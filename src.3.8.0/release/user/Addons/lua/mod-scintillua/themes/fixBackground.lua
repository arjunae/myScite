--~ Override some scintilla default style here, because some of them have non neutral backgrounds
local l =  require('lexer')
l.TYPE = 'constant'

local property = l.property
--print(property['lexer.lpeg.home'])
print("check SciTE luaScopes 'colour.default' : " .. props['colour.default'])

