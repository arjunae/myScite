require 'winapi'
require 'winapiex'

do

local _put
local _putTable

-- find SciTE director HWND (NOT HWND of main window!)
local win = winapi.find_window('DirectorExtension', nil)
sciteDirExtHwnd = win:get_handle()
if sciteDirExtHwnd==0 then os.exit(1) end

----------------------------------------
--
----------------------------------------
_put = function (str)
	if type(str)=="table" then return _putTable(str) end
	str = tostring(str)
	str = str:gsub("\\", "\\\\")
	winapiex.send(sciteDirExtHwnd, "extender:print > "..str)
end

----------------------------------------
--
----------------------------------------
_putTable = function (t, indent)
	if indent==nil then indent="" end
	for i,v in pairs(t) do
		if type(v)=="table" then 
			_put(i..':')
			_putTable(v, indent.."  ")
		else
			_put(indent..i..': '..v)
		end
	end
end

----------------------------------------
--
----------------------------------------
local function _err (str)
	str = tostring(str)
	str = str:gsub("\\", "\\\\")
	winapiex.send(sciteDirExtHwnd, "extender:print - "..str)
end

----------------------------------------
-- sends command to scite
----------------------------------------
local function _cmd (cmdStr)
	cmdStr = cmdStr:gsub("\\", "\\\\")
	winapiex.send(sciteDirExtHwnd, cmdStr)
end

----------------------------------------
--
----------------------------------------
local function _getScintilla ()
	
	-- find SciTE window
	win = winapi.find_window("SciTEWindow", nil)
	hwndScite = win:get_handle()
	if hwndScite==0 then os.exit(1) end
	
	-- find first child (class="SciTEWindowContent")
	local children = {}
	win:enum_children (function(c)
		table.insert(children, c)
	end)
	win = children[1]
	
	-- find first child (class="Scintilla")
	children = {}
	win:enum_children (function(c)
		table.insert(children, c)
	end)
	return children[1]
end

----------------------------------------
--
----------------------------------------
local function _listen (hwndSidebar, globalCallbackName)
	-- 	WM_COPYDATA = 74 
	winapiex.msgListen(hwndSidebar, {74}, globalCallbackName)
end

----------------------------------------
-- scite lib interface
----------------------------------------
scite = {
	put = _put,
	putTable = _putTable,
	err = _err,
	cmd = _cmd,
	getScintilla = _getScintilla,
	listen = _listen
}

end
