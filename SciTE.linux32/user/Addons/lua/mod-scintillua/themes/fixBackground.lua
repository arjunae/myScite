local property = require('lexer').property

-- Default style.
local font, size = 'Bitstream Vera Sans Mono', 10
if WIN32 then
  font = 'Courier New'
elseif OSX then
  font, size = 'Monaco', 12
end

-- Scintillua has another idea of doing themeing, so fix bg here.
local l = require('lexer')
l.TYPE = l.CONSTANT

-- lua WTF ....try copying that line over the entries above ?!
property['style.default'] = 'font:'..font..',size:'..size
--..','..props['colour.foreground']..","..props['colour.background']



