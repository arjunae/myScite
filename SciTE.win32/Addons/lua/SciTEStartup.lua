-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

-- the following snip works synchronous. so cant used to wait for the pane to become avaiable.
-- scite forces any addon to be prepared for been called in that state.
-- Fixme: shouldnt there be an document.ready ? 
--pcall(function() len=(editor.Length) end)
--if len~=nil then print (len) end

--------------------------------- Lua Addons
-- Load Extman
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-extman\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-extman\\extman.lua')

-- Load mod-mitchell 
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-mitchell\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-mitchell\\scite.lua')

-- Load Orthospell 
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-hunspell\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-orthospell\\orthospell.lua')

-- Load Sidebar (which uses "eventmanager.lua")
package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
dofile(props["SciteDefaultHome"]..'\\Addons\\lua\\mod-sidebar\\URL_detect.lua')


--print("lua: startup script reload ")
--function OnMarginClick(modifiers,position,margin)
--print(modifiers)
	--return true
--end

