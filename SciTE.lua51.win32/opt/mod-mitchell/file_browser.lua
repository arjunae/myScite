--[[
  Mitchell's file_browser.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Filesystem browser for the scite module.
-- It uses a tree-view like structure with indentation instead of
-- fold markers.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   LS_CMD: The command to list files and directories one line at a time
--     (directories having an appended slash to them).
--   LSD_CMD: The command to list details of files and directories.
--   REDIRECT1: The command line symbol used for redirecting STDOUT to a file.
--   REDIRECT2: The command line symbol used for redirecting STDERR to a file.
--   FILE_OUT: Location of the temporary file that will contain output for
--     various operations.
--   LINE_END: The line end character for the specific PLATFORM.
--   DIR_SEP: The character that separates directories for the specific
--     PLATFORM.
module('modules.scite.filebrowser', package.seeall)

-- platform-specific options
local PLATFORM = _G.PLATFORM or 'linux'
local LS_CMD, LSD_CMD, REDIRECT1, FILE_OUT, ROOT, LINE_END
local LS_CMD2, REDIRECT2, DIR_SEP
if PLATFORM == 'linux' then
  LS_CMD    = 'ls -1p '
  LSD_CMD   = 'ls -dhl '
  REDIRECT1 = ' 1> '
  REDIRECT2 = ' 2>&1 '
  FILE_OUT  = '/tmp/scite_output'
  ROOT      = '/'
  LINE_END  = '\n'
  DIR_SEP   = '/'
elseif PLATFORM == 'windows' then
  LS_CMD    = 'dir /A:D /B '
  LS_CMD2   = 'dir /A:-D /B '
  LSD_CMD   = 'dir /A /Q '
  REDIRECT1 = ' 1> '
  REDIRECT2 = ' 2>&1 '
  FILE_OUT  = os.getenv('TEMP')..'\\scite_output.txt'
  ROOT      = 'C:\\'
  LINE_END  = '\r\n'
  DIR_SEP   = '\\'
end
-- end options

-- local functions
local get_line, get_sel_or_line, get_dir_contents, get_abs_path
local is_dir, dir_is_open, open_dir, close_dir

---
-- Displays the directory structure.
-- The root directory of the structure displayed is determined by selected text
-- or the contents of the current line. If a directory is specified, it is
-- assumed to be an absolute path. If none is specified, the ROOT directory is
-- displayed.
function create()
  local root_dir = get_sel_or_line()
  if root_dir ~= '' then
    if root_dir:sub(#root_dir) ~= DIR_SEP then root_dir = root_dir..DIR_SEP end
    ROOT = root_dir
  end
  editor:SetText('File Browser - '..ROOT..LINE_END..LINE_END)
  editor:AppendText( get_dir_contents(ROOT) )
  editor:GotoLine(2)
end

---
-- Performs an intelligent file browser action.
-- If the item on the current line is a closed directory, it is 'opened', and
-- all of its contents are displayed with an additional level of indentation.
-- If the item is an open directory, it is 'closed', and its contents are
-- hidden. If the item is a file, it is opened in SciTE.
function action()
  if editor:GetLine(0) ~= 'File Browser - '..ROOT..LINE_END then return end

  local pos = editor.CurrentPos
  local item = get_line():match('^%s*(.+)$')
  if not item then return end

  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local abs_path = get_abs_path(item, line_num)
  if is_dir(item) then
    if dir_is_open(line_num) then
      close_dir(abs_path, line_num)
    else
      open_dir(abs_path, line_num)
    end
    editor:SetSel(pos, pos)
  else
    editor:SetSel(pos, pos)
    scite.Open( abs_path:sub(2, -2) )
  end
end

---
-- Retrieves details about a file or directory and displays it in a calltip.
function show_file_details()
  if editor:GetLine(0) ~= 'File Browser - '..ROOT..LINE_END then return end

  local pos = editor.CurrentPos
  local item = get_line():match('^%s*(.+)$')
  if not item then return end
  editor:SetSel(pos, pos)

  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local abs_path = get_abs_path(item, line_num)
  os.execute(LSD_CMD..abs_path..REDIRECT1..FILE_OUT..REDIRECT2)

  local f = io.open(FILE_OUT)
  local out
  if PLATFORM == 'linux' then
    out = f:read('*all')
    local perms, num_dirs, owner, group, size, mod_date =
      out:match('^(%S-)%s(%d-)%s(%S-)%s(%S-)%s(%S-)%s([%d-]-%s[%d:]-)%s.+$')
    out = item..'\n'..
          'Perms:\t'..perms..'\n'..
          '#Dirs:\t'..num_dirs..'\n'..
          'Owner:\t'..owner..'\n'..
          'Group:\t'..group..'\n'..
          'Size:\t'..size..'\n'..
          'Date:\t'..mod_date
  elseif PLATFORM == 'windows' then
    for line in f:lines() do
      if line:match('^%d') then
        local mod_date, size, owner =
          line:match('^([%d/]+%s%s[%d:]+%s[AP]M)%s+([%d,]+)%s([^%s]+).*$')
        if mod_date and size and owner then
          out = item..'\n'..
                'Owner:\t'..owner..'\n'..
                'Size:\t'..size..'\n'..
                'Date:\t'..mod_date
        else
          out = item..'\nCan\'t stat directory'
        end
        break
      end
    end
  end
  f:close()

  editor:CallTipShow(editor.CurrentPos, out)
end

---
-- [Local function] Returns the text on the current line.
get_line = function()
  editor:Home() editor:LineEndExtend()
  return editor:GetSelText()
end

---
-- [Local function] Returns the current selection or the text on the current
-- line.
get_sel_or_line = function()
  if editor:GetSelText() == '' then return get_line() end
  return editor:GetSelText()
end

---
-- [Local function] Returns the contents of a directory.
-- @param abs_path The absolute path of the directory to get the contents of.
get_dir_contents = function(abs_path)
  os.execute(LS_CMD..abs_path..REDIRECT1..FILE_OUT..REDIRECT2)
  local f = io.open(FILE_OUT)
  local out = ''
  if PLATFORM == 'linux' then
    out = f:read('*all')
  elseif PLATFORM == 'windows' then
    -- These are directories.
    for line in f:lines() do out = out..line..DIR_SEP..LINE_END end
    f:close()
    os.execute(LS_CMD2..abs_path..REDIRECT1..FILE_OUT..REDIRECT2)
    f = io.open(FILE_OUT)
    out = out..f:read('*all') -- these are files
  end
  f:close()
  return out
end

---
-- [Local function] Returns the absolute path of the file or directory on the
-- current line.
-- It does this by iterating up lines, noting any changes in indentation. If
-- one is found, that is a directory name and prepends it to the absolute path.
-- It does this until it reaches the root level. At this point this is the
-- absolute path of the file or directory and it is returned.
-- @param item The name of the file or directory on the current line.
-- @param line_num The line number item is on.
get_abs_path = function(item, line_num)
  local indentation = editor.LineIndentation[line_num]
  if indentation == 0 then return '"'..ROOT..item..'"' end
  local abs_path = item
  local target_indent = indentation - editor.Indent
  local patt = '^%s*(.+)$'
  for i = line_num, 2, -1 do -- ignore "File Browser - ROOT\n\n"
    if editor.LineIndentation[i] == target_indent then
      local part = editor:GetLine(i):match(patt)
      abs_path = part..abs_path
      target_indent = target_indent - editor.Indent
      if target_indent < 0 then break end
    end
  end
  abs_path = abs_path:gsub(LINE_END, '')
  return '"'..ROOT..abs_path..'"'
end

---
-- [Local function] Determines if the item in question is a directory or not.
-- The list commands make sure directories are specified with a DIR_SEP at the
-- end, so this is a simple check.
-- @param item The name of the file or directory in question.
is_dir = function(item) return item:sub(#item) == DIR_SEP end

---
-- [Local function] Determines if the specified directory is open or not.
-- Open directories have indented files and directories below the line they are
-- on.
-- @param line_num The line number of the directory in question.
dir_is_open = function(line_num)
  local indentation = editor.LineIndentation[line_num]
  return editor.LineIndentation[line_num + 1] > indentation
end

---
-- [Local function] Opens a closed directory and displays its contents below in
-- an additional level of indentation.
-- @param abs_path The absolute path of the directory to open.
-- @param line_num The line number the directory is on.
open_dir = function(abs_path, line_num)
  local contents = get_dir_contents(abs_path)
  local pos = editor:PositionFromLine(line_num + 1)
  local indentation = editor.LineIndentation[line_num]
  if #contents > 0 then
    editor:InsertText(pos, contents)
    editor:SetSel(pos, pos + #contents)
    for i = 0, indentation / editor.Indent do editor:Tab() end
  end
end

---
-- [Local function] Closes an open directory, hiding its contents.
-- All lines with indentation levels higher than the directory's indentation
-- level are removed.
-- @param abs_path The absolute path of the directory to close.
-- @param line_num The line number the directory is on.
close_dir = function(abs_path, line_num)
  local indentation = editor.LineIndentation[line_num]
  local last_line
  for i = line_num + 1, editor.LineCount - 1 do
    if editor.LineIndentation[i] <= indentation then
      last_line = i - 1
      break
    end
  end
  local start_pos, end_pos
  start_pos = editor.LineEndPosition[line_num]
  end_pos   = editor.LineEndPosition[last_line]
  editor:remove(start_pos, end_pos)
end
