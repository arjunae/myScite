--~ Override some scintilla default style here, because some of them have non neutral backgrounds.
--~ Currently, Backport 3.8.0 doesnt support overriding. So we use Scintillua lexLPeg.cxx, which works fine.
local l =  require('lexer')
local property = require('lexer').property

property['style.whitespace']= props['colour.default']
property['style.comment']= props['colour.keyword'] ..","..props['colour.background']
property['style.type']= props['colour.keyword4'] ..","..props['colour.background']
property['style.keyword']= props['colour.keyword6'] ..","..props['colour.background']
property['style.function']= props['colour.extcmd'] ..","..props['colour.background']
property['style.identifier']= props['colour.identifier'] ..","..props['colour.background']
property['style.label']= props['colour.identifier'] ..","..props['colour.accent.back']
property['style.variable']= props['colour.preproc'] ..","..props['colour.accent.back']
property['style.constant']= props['colour.keyword6'] ..","..props['colour.accent.back']
property['style.preprocessor']= props['colour.preproc'] ..","..props['colour.accent.back']

--[[
style.default=props['colour.default']
style.embedded=props['style.*.15']
style.controlchar=props['style.*.36']
style.class=props['style.*.19']
style.nothing=
style.constant=props['colour.globalclass'],props['colour.background']
style.definition=props['style.*.16']
style.error=props['colour.error']
style.function=props['style.*.5']
style.number=props['colour.number']
style.operator=props['colour.operator']
style.regex=$(style.*.15)
style.string=props['colour.string']
style.preprocessor=props['colour.preproc']
style.tag=$(style.*.15)
style.variable=props['colour.keyword3']
style.action=props['colour.globalclass']
]]
