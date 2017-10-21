-- Extman is a Lua script manager for SciTE. It enables multiple scripts to capture standard events
-- without interfering with each other. For instance, scite_OnDoubleClick() will register handlers
-- for scripts that need to know when a double-click event has happened. (To know whether it
-- was in the output or editor pane, just test editor.Focus).  It provides a useful function scite_Command
-- which allows you to define new commands without messing around with property files (see the
-- examples in the scite_lua directory.)
-- extman defines three new convenience handlers as well:
--scite_OnWord (called when user has entered a word)
--scite_OnEditorLine (called when a line is entered into the editor)
--scite_OnOutputLine (called when a line is entered into the output pane)

-- test
require 'winapi'

local _MarginClick,_DoubleClick,_SavePointLeft = {},{},{}
local _SavePointReached,_Open,_Close,_SwitchFile = {},{},{},{}
local _BeforeSave,_Save,_Char = {},{},{}
local _Word,_LineEd,_LineOut = {},{},{}
local _OpenSwitch = {}
local _UpdateUI = {}
local _UserListSelection
local _remove = {}
local append = table.insert
local find = string.find
local size = table.getn
local sub = string.sub
local gsub = string.gsub

function OnUserListSelection(tp,str)
  if _UserListSelection then
     local callback = _UserListSelection
     _UserListSelection = nil
     return callback(str)
  else return false end
end

local function DispatchOne(handlers,arg)
  for i,handler in pairs(handlers) do
    local fn = handler
    if _remove[fn] then
        handlers[i] = nil
       _remove[fn] = nil
    end
    local ret = fn(arg)
    if ret then return ret end
  end
  return false
end

-- these are the standard SciTE Lua callbacks  - we use them to call installed extman handlers!
function OnMarginClick()
  return DispatchOne(_MarginClick)
end

function OnDoubleClick()
  return DispatchOne(_DoubleClick)
end

function OnSavePointLeft()
  return DispatchOne(_SavePointLeft)
end

function OnSavePointReached()
  return DispatchOne(_SavePointReached)
end

function OnChar(ch)
  return DispatchOne(_Char,ch)
end

function OnSave(file)
  return DispatchOne(_Save,file)
end

function OnBeforeSave(file)
  return DispatchOne(_BeforeSave,file)
end

function OnSwitchFile(file)
  return DispatchOne(_SwitchFile,file)
end

function OnOpen(file)
  return DispatchOne(_Open,file)
end

-- added by VS
function OnClose(file)
  return DispatchOne(_Close,file)
end

function OnUpdateUI()
  if editor.Focus then
     return DispatchOne(_UpdateUI)
  else
     return false
  end
end

-- may optionally ask that this handler be immediately
-- removed after it's called
local function append_unique(tbl,fn,remove)
  local once_only
  if type(fn) == 'string' then
     once_only = fn == 'once'
     fn = remove
     remove = nil
     if once_only then _remove[fn] = fn end
  else
    _remove[fn] = nil
  end
  local idx
  for i,handler in pairs(tbl) do
     if handler == fn then idx = i; break end
  end
  if idx then
    if remove then
      table.remove(tbl,idx)
    end
  else
    if not remove then
      append(tbl,fn)
    end
  end
end

-- this is how you register your own handlers with extman
function scite_OnMarginClick(fn,remove)
  append_unique(_MarginClick,fn,remove)
end

function scite_OnDoubleClick(fn,remove)
  append_unique(_DoubleClick,fn,remove)
end

function scite_OnSavePointLeft(fn,remove)
  append_unique(_SavePointLeft,fn,remove)
end

function scite_OnSavePointReached(fn,remove)
  append_unique(_SavePointReached,fn,remove)
end

function scite_OnOpen(fn,remove)
  append_unique(_Open,fn,remove)
end

-- added by VS
function scite_OnClose(fn,remove)
  append_unique(_Close,fn,remove)
end

function scite_OnSwitchFile(fn,remove)
  append_unique(_SwitchFile,fn,remove)
end

function scite_OnBeforeSave(fn,remove)
  append_unique(_BeforeSave,fn,remove)
end

function scite_OnSave(fn,remove)
  append_unique(_Save,fn,remove)
end

function scite_OnUpdateUI(fn,remove)
  append_unique(_UpdateUI,fn,remove)
end

function scite_OnChar(fn,remove)
  append_unique(_Char,fn,remove)
end

function scite_OnOpenSwitch(fn,remove)
  append_unique(_OpenSwitch,fn,remove)
end

local function buffer_switch(f)
--- OnOpen() is also called if we move to a new folder
   if not find(f,'[\\/]$') then
      DispatchOne(_OpenSwitch,f)
   end
end

scite_OnOpen(buffer_switch)
scite_OnSwitchFile(buffer_switch)

local next_user_id = 13 -- arbitrary

-- the handler is always reset!
function scite_UserListShow(list,start,fn)
  local s = ''
  local sep = ';'
  local n = size(list)
  for i = start,n-1 do
      s = s..list[i]..sep
  end
  s = s..list[n]
  _UserListSelection = fn
  local pane = editor
  if not pane.Focus then pane = output end
  pane.AutoCSeparator = string.byte(sep)
  pane:UserListShow(next_user_id,s)
  pane.AutoCSeparator = string.byte(' ')
end

 local word_start,in_word,current_word

 local function on_word_char(s)
     if not in_word then
        if find(s,'%w') then
      -- we have hit a word!
         word_start = editor.CurrentPos
         in_word = true
         current_word = s
      end
    else -- we're in a word
   -- and it's another word character, so collect
     if find(s,'%w') then
       current_word = current_word..s
     else
       -- leaving a word; call the handler
       local word_end = editor.CurrentPos
       DispatchOne(_Word, {word=current_word,
               startp=word_start,endp=editor.CurrentPos,
               ch = s
            })
       in_word = false
     end
    end
  -- don't interfere with usual processing!
    return false
  end

function scite_OnWord(fn,remove)
  append_unique(_Word,fn,remove)
  if not remove then
     scite_OnChar(on_word_char)
  else
     scite_OnChar(on_word_char,'remove')
  end
end

local last_pos = 0

local function grab_line_from(pane)
  local line_pos = pane.CurrentPos
  local lineno = pane:LineFromPosition(line_pos)-1
  -- strip linefeeds (Windows is a special case as usual!)
  local endl = 2
  if scite_GetProp('PLAT_WIN') then endl = 3 end
  local line = string.sub(pane:GetLine(lineno),1,-endl)
  return line
end

local function on_line_char(ch,result)
  if ch == '\n' or ch == '\r' then
       if ch == '\n' then
       if editor.Focus then
            DispatchOne(_LineEd,grab_line_from(editor))
       else
            DispatchOne(_LineOut,grab_line_from(output))
      end
      return result
      end
  end
  return false
end

local function on_line_editor_char(ch)
  return on_line_char(ch,false)
end

local function on_line_output_char(ch)
  return on_line_char(ch,true)
end

local function set_line_handler(fn,rem,handler,on_char)
  append_unique(handler,fn,rem)
  if not rem then
     scite_OnChar(on_char)
  else
     scite_OnChar(on_char,'remove')
  end
end

function scite_OnEditorLine(fn,rem)
  set_line_handler(fn,rem,_LineEd,on_line_editor_char)
end

function scite_OnOutputLine(fn,rem)
  set_line_handler(fn,rem,_LineOut,on_line_output_char)
end

function scite_GetProp(key,default)
   local val = props[key]
   if val and val ~= '' then return val
   else return default end
end

local GTK = scite_GetProp('PLAT_GTK')
local default_path
local tmpfile
if GTK then
  default_path = props['SciteUserHome']
  tmpfile = '/tmp/.scite-temp-files'
else
  default_path = props['SciteDefaultHome']
  tmpfile = '\\scite_temp1'
end

function scite_Files(mask)
  local f,path

  mask = gsub(mask,'/','\\')
  _,_,path = find(mask,'(.*\\)')

  -- VS
  local cmd = 'dir /b "'..mask..'" 2>nul'
  local err,res = winapi.execute (cmd, 0)
  local eol = '\r\n'
  if res:sub(-string.len(eol))~=eol then res=res..eol end
  local files = {}
  for line in res:gmatch("(.-)\r\n") do
    if line~='' then append(files, path..line) end
  end
  return files
end

function scite_FileExists(f)
  local f = io.open(f)
  if not f then return false
  else
    f:close()
    return true
  end
end

function scite_CurrentFile()
  return props['FilePath']
end

function scite_WordAtPos(pos)
  if not pos then pos = editor.CurrentPos end
  local p2 = editor:WordEndPosition(pos,true)
  local p1 = editor:WordStartPosition(pos,true)
  return editor:textrange(p1,p2)
end

-- allows you to bind given Lua functions to shortcut keys
-- without messing around in the properties files!

function split(s,delim)
  res = {}
  while true do
    p = find(s,delim)
    if not p then
      append(res,s)
      return res
    end
    append(res,sub(s,1,p-1))
    s = sub(s,p+1)
  end
end

function splitv(s,delim)
  return unpack(split(s,delim))
end

local idx = 10
local shortcuts_used = {}

function scite_Command(tbl)
  if type(tbl) == 'string' then
     tbl = {tbl}
  end
  for i,v in pairs(tbl) do
     local name,cmd,mode,shortcut = splitv(v,'|')
   if not shortcut then
        shortcut = mode
    mode = '.*'
     else
    mode = '.'..mode
     end
   -- has this command been defined before?
   local old_idx = 0
   for ii = 10,idx do
      if props['command.name.'..ii..mode] == name then old_idx = ii end
   end
   if old_idx == 0 then
     local which = '.'..idx..mode
     props['command.name'..which] = name
     props['command'..which] = cmd
     props['command.subsystem'..which] = '3'
     props['command.mode'..which] = 'savebefore:no'
     if shortcut then
       local cmd = shortcuts_used[shortcut]
       if cmd then
        print('Error: shortcut already used in "'..cmd..'"')
       else
      --   print(name,cmd,shortcut)
       props['command.shortcut'..which] = shortcut
       shortcuts_used[shortcut] = name
       end
     end
     idx = idx + 1
    end
  end
end

-- this will quietly fail....

local loaded = {}
local function silent_dofile(f)
 if scite_FileExists(f) then
  --f = gsub(f,'\\','/')
  if not loaded[f] then
    dofile(f)
    loaded[f] = true
  else
    print('already loaded',f)
  end
 end
end

function scite_dofile(f)
 f = default_path..'/'..f
 silent_dofile(f)
end

local path
local lua_dir = scite_GetProp('ext.lua.directory')
if lua_dir then
  path = lua_dir
else
  path = default_path..'/Addons/lua/scite_lua'
end

function scite_require(f)
  f = path..'/'..f
  silent_dofile(f)
end

if not GTK then
   scite_dofile 'scite_other.lua'
end

local script_list = scite_Files(path..'/*.lua')

if not script_list then
  print('Error: no files found in '..path)
else
  for i,file in pairs(script_list) do
    silent_dofile(file)
  end
end

