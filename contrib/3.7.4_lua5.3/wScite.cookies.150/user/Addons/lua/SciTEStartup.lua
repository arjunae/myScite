-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"].."\\user"
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

---- SciTEStartup.lua gets called by extman, to ensure its available here.
-- Load ctags (which uses "eventmanager.lua")
--dofile(props["SciteDefaultHome"]..'\\user\\Addons\\lua\\mod-ctags\\ctagsd.lua')

--print("Called StartupScript")
--print(props['command.name.8.*'])
--scite_Command('Tic Tac Toe|TicTacToe|Ctrl+8')