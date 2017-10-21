-- Lua backend for SciTE Sidebar
-- (c) Valentin Schmidt 2016

package.path = package.path..';/Addons/lua/mod-sidebar/sidebar/?.lua'

require 'os'
require 'winapi'
require 'winapiex'
require 'functions_cfg'

-- set to true to show a console
debug = false

----------------------------------------
-- Start sidebar
----------------------------------------
function startSidebar ()
	if debug then -- debug mode (shows console window)
		winapi.setenv('PATH', props['SciteDefaultHome']..'\\Addons\\lua\\mod-sidebar;'..os.getenv("PATH"))
		winapi.shell_exec(
			'open',
			'cmd.exe', 
			'/clua.exe '..props['SciteDefaultHome']..'\\Addons\\lua\\mod-sidebar\\sidebar.lua & pause',
			props['SciteDefaultHome']
		)
	else -- runtime mode
		winapi.setenv('PATH', props['SciteDefaultHome']..';'..os.getenv("PATH"))
		winapi.shell_exec(
			'open',
			props['SciteDefaultHome']..'\\Addons\\lua\\mod-sidebar\\wlua.exe', 
			props['SciteDefaultHome']..'\\Addons\\lua\\mod-sidebar\\sidebar.lua'
		)
	end
end
	
----------------------------------------
-- Toggles visibility of sidebar
----------------------------------------
function toggleSidebar ()
  -- check if sidebar is already open
  local win = winapi.find_window ('QWidget', 'Sidebar')
  if win:get_handle()==0 then 
  	startSidebar()
  else
    if win:is_visible() then
      win:show(0) -- SW_HIDE
    else
      win:show(4) -- SW_SHOWNOACTIVATE
    end
  end
end

----------------------------------------
-- Sends WM_COPDATA message to sidebar
----------------------------------------
function notifySidebar (data)
  local win = winapi.find_window('QWidget', 'Sidebar')
  local hwnd = win:get_handle()
  if hwnd~=0 then
    local msg = ':'..hwnd..':'..data
    local res = winapiex.send(hwnd, msg)
  end
end

----------------------------------------
-- Opens specified tab in sidebar
----------------------------------------
function sidebarShowTab (name)
  local win = winapi.find_window ('QWidget', 'Sidebar')
  if win:get_handle()~=0 then
    notifySidebar("showTab:"..name)
  else
    print('>Sidebar not started yet. First start it with Alt+E.')
  end
end

----------------------------------------
-- Updates the function list in sidebar (if sidebar is running)
----------------------------------------
function sidebarUpdateFunctions()

  local fn = props['FilePath']

  -- send list of functions to sidebar
  local functions = ''
  local ext = fn:match("%.([^%s]*)$")
  local t = FUNCTION_TABLE[ext]
  if t~=nil then
    local code = "\r\n"..editor:GetText()

    -- loop over regexps
    for i,regex in ipairs(t.regex) do
      for res in string.gmatch(code, '[\r\n]'..regex) do
        functions = functions..res..','
      end
    end

    if (functions) then functions = string.sub(functions, 1, -2) end
  end
  notifySidebar("functions:"..functions)
end

----------------------------------------
-- Shows current file (buffer) in Windows Explorer
-- (if file wasn't saved yet, nothing happens)
----------------------------------------
function showInWindowsExplorer()
  local fn = props['FilePath']
  if fn:sub(#fn, #fn)~='\\' then
    winapi.execute('explorer.exe /select,"'..props['FilePath']..'"')
  end
end

----------------------------------------
-- Shows current file (buffer) in Sidebar Explorer
-- (if sidebar wasn't started or file wasn't saved yet, nothing happens)
----------------------------------------
function showInSidebarExplorer()
  local fn = props['FilePath']
  if fn:sub(#fn, #fn)~='\\' then
    local win = winapi.find_window ('QWidget', 'Sidebar')
    if win:get_handle()~=0 then
      win:show(4) -- SW_SHOWNOACTIVATE
      notifySidebar("show:"..fn)
    else
      print('>Sidebar not started yet. First start it with Alt+E.')
    end
  end
end

-- CALLBACKS --

----------------------------------------
-- Called by sidebar: clear output pane
----------------------------------------
function onClearOutput()
	output:SetText('')
end

----------------------------------------
-- Called by sidebar: scroll to and select specified function in current buffer
----------------------------------------
function onFunctionSelected(name)

  local ext = props['FilePath']:match("%.([^%s]*)$")
  local t = FUNCTION_TABLE[ext]
  if t==nil then return end

  local code = editor:GetText()
  local search

  for i,fmt in ipairs(t.fmt) do

    search = string.format(fmt, name)

    if string.find(code, search)==1 then
      pos = 0
    else
      pos = string.find(code, "[\n\r]"..search)
    end

    if pos~=nil then

      -- goto line
      local lineNum = editor:LineFromPosition(pos)
      editor:GotoLine(lineNum)

      -- select line
      posEnd = editor.LineEndPosition[lineNum]
      editor:SetSel(pos, posEnd) -- Select a range of text.
      editor.FirstVisibleLine = lineNum - 3
      return
    end
  end
end

-- EVENT HANDLERS --

scite_OnOpen(sidebarUpdateFunctions)
scite_OnSwitchFile(sidebarUpdateFunctions)
scite_OnSave(sidebarUpdateFunctions)
scite_OnSave(function(fn)
  notifySidebar("saved:"..fn)
end)
scite_OnClose(function(fn)
  if fn~="" then
    notifySidebar("closed:"..fn)
  end
end)

-- ADD MENU ITEMS --

scite_Command {
  'Sidebar show/hide|toggleSidebar|Alt+E',
  'Sidebar: Explorer|sidebarShowTab explorer|Alt+Shift+E',
  'Sidebar: FTP|sidebarShowTab ftp|Alt+Shift+T',
  'Sidebar: Functions|sidebarShowTab functions|Alt+Shift+F',
  'Sidebar: Bookmarks|sidebarShowTab bookmarks|Alt+Shift+B',
  'Sidebar: Projects|sidebarShowTab projects|Alt+Shift+P',
  'Show in Windows Explorer|showInWindowsExplorer|Alt+W',
  'Show in Sidebar Explorer|showInSidebarExplorer|Alt+X'
}

-- autostart sidebar?
if (tonumber(props['sidebar.autostart'])==1) then startSidebar() end
