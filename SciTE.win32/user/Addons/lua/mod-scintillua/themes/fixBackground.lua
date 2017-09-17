local property = require('lexer').property

-- Default style.
local font, size = 'Bitstream Vera Sans Mono', 10
if WIN32 then
  font = 'Consolas', 9
elseif OSX then
  font, size = 'Monaco', 12
end

-- Scintillua has another idea of doing themeing.
-- so we need to get a ref to the style props or define them by hand...
local l =  require('lexer')
l.TYPE = l.CONSTANT
--property['style.type'] ='fore:#9A9A9A'


--property['style.nothing'] = ''
--property['style.class'] = 
--property['style.constant'] = 
--property['style.comment'] = 'font:'..font..',size:'..size..','..props["colour.comment.line"]..","..props["colour.background"]
--property['style.default'] = 'font:'..font..',size:'..size..','..props["colour.foreground"]..","..props["colour.background"]
--property['style.definition'] =
--property['style.error'] = 
--property['style.function'] = 'font:'..font..',size:'..size..','..props["colour.keyword"]..","..props["colour.background"]
--property['style.keyword'] = 'font:'..font..',size:'..size..','..props["colour.keyword"]..","..props["colour.background"]
--property['style.label'] = 
--property['style.number'] = 'font:'..font..',size:'..size..','..props["colour.number"]..","..props["colour.background"]
--property['style.operator'] = 'font:'..font..',size:'..size..','..props["colour.operator"]..","..props["colour.background"]
--property['style.regex'] = 
--property['style.string'] = 'font:'..font..',size:'..size..','..props["colour.string"]..","..props["colour.background"]
--property['style.preprocessor'] =
--property['style.tag'] = 
--property['style.type'] = 'font:'..font..',size:'..size..','..props["colour.string"]..","..props["colour.background"]
--property['style.variable'] = 
--property['style.identifier'] = 'font:'..font..',size:'..size..','..props["colour.identifier"]..","..props["colour.background"]
--property['style.action'] = 'font:'..font..',size:'..size..','..props["colour.keyword2"]..","..props["colour.background"]
--property['style.whitespace'] = ''
--property['style.embedded'] =


-- Predefined styles.
--property['style.linenumber'] = 
--property['style.bracelight'] = 
--property['style.bracebad'] = 
--property['style.controlchar'] = 
--property['style.indentguide'] =
--property['style.calltip'] = 
--property['style.folddisplaytext'] =
