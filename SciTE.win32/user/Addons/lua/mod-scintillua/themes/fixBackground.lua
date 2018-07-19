--~ Override some scintilla default style here, because some of them have non neutral backgrounds
local l =  require('lexer')
local property = require('lexer').property
l.TYPE = 'constant'

--print(property['lexer.lpeg.home'])
--print("check SciTE luaScopes 'colour.globalclass' : " .. props['colour.globalclass'])

--property['style.type']=props['colour.globalclass'] ..",".. props['colour.background']
--property['style.type']='fore:#33AAAA,back:#010101'
--property['style.constant']='fore:#AAAAAA,back:#010101'
