--~ Override some scintilla default style here, because some of them have non neutral backgrounds
local l =  require('lexer')
local property = require('lexer').property
--l.TYPE = 'constant'

print(property['lexer.lpeg.home'])
--print("check SciTE luaScopes 'colour.globalclass' : " .. props['colour.globalclass'])

--property['style.type']=props['colour.globalclass'] ..",".. props['colour.background']
property['style.type']='fore:#AAAAAA,back:#010101'
property['style.constant']='fore:#AAAAAA,back:#010101'

--property['style.default']='fore:#AAAAAA,back:#010101'

print(property['style.type'])
--[[
style.default=props['colour.default']
style.whitespace=props['colour.default']
style.comment=props['style.*.2']
style.embedded=props['style.*.15']
style.controlchar=props['style.*.36']
style.type=props['colour.globalclass'],props['colour.background']
style.class=props['style.*.19']
style.nothing=
style.constant=props['colour.globalclass'],props['colour.background']
style.definition=props['style.*.16']
style.error=props['colour.error']
style.function=props['style.*.5']
--style.keyword=$(style.*.15)
--style.label=$(style.*.15)
style.number=props['colour.number']
style.operator=props['colour.operator']
--style.regex=$(style.*.15)
style.string=props['colour.string']
style.preprocessor=props['colour.preproc']
--style.tag=$(style.*.15)
style.variable=props['colour.keyword3']
style.identifier=props['colour.identifier']
style.action=props['colour.globalclass']
]]
