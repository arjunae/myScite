require("hunspell");  -- assuming hunspell.dll 

local dictpath = ".\\"
local dictname = "en_US"
hunspell.init(dictpath..dictname..".aff", dictpath..dictname..".dic");
