-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"].."\\user"
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

---- SciTEStartup.lua gets called by extman, to ensure its available here.
-- Load Sidebar (which uses "eventmanager.lua")
--package.path = package.path .. ";"..defaultHome.."\\Addons\\lua\\mod-sidebar\\?.lua;"
--dofile(props["SciteDefaultHome"]..'\\user\\Addons\\lua\\mod-sidebar\\URL_detect.lua')

--print("Called StartupScript")
--print(props['command.name.8.*'])
--scite_Command('Tic Tac Toe|TicTacToe|Ctrl+8')