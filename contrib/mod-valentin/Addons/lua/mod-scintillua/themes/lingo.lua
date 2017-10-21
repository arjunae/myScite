-- SciTE lexer theme for Scintillua.

-- Scintillua has another idea of doing themeing, so fix bg here.
local l =  require('lexer')
l.TYPE = l.CONSTANT

-- lua WTF ....try copying that line over the entries above ?!
property['style.default'] = 'font:'..font..',size:'..size..','..props["colour.foreground"]..","..props["colour.background"]

local property = require('lexer').property

property['color.black'] = '#000000'
property['color.grey'] = '#808080'
property['color.white'] = '#FFFFFF'

-- new
property['color.comment'] = '#C80000'

property['color.keyword'] = '#0000C8'
property['color.function'] = '#008000'

--property['color.constant'] = '#0000C8'

-- Default style.
local font, size = 'Courier New', 10
if WIN32 then
  font = 'Courier New'
elseif OSX then
  font, size = 'Monaco', 12
end
property['style.default'] = 'font:'..font..',size:'..size..
                            ',fore:$(color.black),back:$(color.white)'

-- Token styles.
property['style.nothing'] = ''
--property['style.class'] = 'fore:$(color.black),bold'
property['style.comment'] = 'fore:$(color.comment)'

property['style.function'] = 'fore:$(color.function)'--,bold
property['style.keyword'] = 'fore:$(color.keyword)' --,bold'

--property['style.constant'] = 'fore:$(color.constant)' --,bold'

property['style.definition'] = 'fore:$(color.black),bold'
--property['style.error'] = 'fore:$(color.red)'
--property['style.label'] = 'fore:$(color.teal),bold'
property['style.number'] = 'fore:$(color.grey)'
--property['style.operator'] = 'fore:$(color.black),bold'
--property['style.regex'] = '$(style.string)'
property['style.string'] = 'fore:$(color.grey)'
--property['style.preprocessor'] = 'fore:$(color.yellow)'
--property['style.tag'] = 'fore:$(color.teal)'
--property['style.type'] = 'fore:$(color.blue)'
property['style.variable'] = 'fore:$(color.black)'
property['style.whitespace'] = ''
--property['style.embedded'] = 'fore:$(color.blue)'
--property['style.identifier'] = '$(style.nothing)'

-- Predefined styles.
property['style.linenumber'] = 'back:#C0C0C0'
property['style.bracelight'] = 'fore:#0000FF,bold'
property['style.bracebad'] = 'fore:#FF0000,bold'
property['style.controlchar'] = '$(style.nothing)'
property['style.indentguide'] = 'fore:#C0C0C0,back:$(color.white)'
property['style.calltip'] = 'fore:$(color.white),back:#444444'
