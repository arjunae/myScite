--~ Override some scintilla default style here, because some of them have non neutral backgrounds
local l =  require('lexer')
l.TYPE = 'constant'

--local property = l.property
--print(property['style.whitespace'])

--property['style.whitespace'] = ''
--property['style.embedded'] =
--property['style.linenumber'] = 
--property['style.bracelight'] = 
--property['style.bracebad'] = 
--property['style.controlchar'] = 
--property['style.indentguide'] =
--property['style.calltip'] = 
--property['style.folddisplaytext'] =
--property['style.type'] ='fore:#9A9A9A'
--property['style.default'] = 'font:'..font..',size:'..size..','..props["colour.foreground"]..","..props["colour.background"]
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
--property['style.preprocessor'] = 'font:'..font..',size:'..size..','..props["colour.preproc"]..","..props["colour.background"]
--property['style.tag'] = 
--property['style.nothing'] = 'fore:#AA1111'
--property['style.variable'] = 
--property['style.identifier'] = 'font:'..font..',size:'..size..','..props["colour.identifier"]..","..props["colour.background"]
--property['style.action'] = 'font:'..font..',size:'..size..','..props["colour.keyword2"]..","..props["colour.background"]
