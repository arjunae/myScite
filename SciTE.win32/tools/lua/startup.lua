-- track the amount of allocated memory 
session_used_memory=collectgarbage("count")*1024

-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")
--print("startupScript loaded")

myHome="../../"
package.path = package.path ..";"..myHome.."\\User\\Addons\\lua\\lua\\?.lua;"
package.path = package.path .. ";"..myHome.."\\User\\Addons\\lua\\mod-extman\\?.lua;"

--lua >=5.2.x renamed functions: 
local unpack = table.unpack or unpack
math.mod = math.fmod or math.mod
string.gfind = string.gmatch or string.gfind
--lua >=5.2.x replaced table.getn(x) with #x

-- ##################  Lua Samples #####################
-- ###############################################

