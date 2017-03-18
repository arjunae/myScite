-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."/Addons/?.lua;".. ";"..defaultHome.."/Addons/lua/lua/?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."/Addons/lua/c/?.dll;"

---- SciTEStartup.lua gets called by extman, to ensure its available here.
-- Load mod-mitchell 
package.path = package.path .. ";"..defaultHome.."/Addons/lua/mod-mitchell/?.lua;"
dofile(props["SciteDefaultHome"]..'/Addons/lua/mod-mitchell/scite.lua')

-- Load Orthospell 
package.path = package.path .. ";"..defaultHome.."/Addons/lua/mod-hunspell/?.lua;"
dofile(props["SciteDefaultHome"]..'/Addons/lua/mod-orthospell/orthospell.lua')


--print("lua: startup script reload ")
--function OnMarginClick(modifiers,position,margin)
--print(modifiers)
	--return true
--end

