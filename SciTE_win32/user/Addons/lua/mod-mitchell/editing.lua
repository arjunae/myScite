--[[
  Mitchell's editing.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Editing commands for the scite module.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   FILE_IN: Location of the temporary file used as STDIN for various
--     operations.
--   FILE_OUT: Location of the temporary file that will contain output for
--     various operations.
--   REDIRECT: The command line symbol used for redirecting STDOUT to a file.
--   RUBY_CMD: The command that executes the Ruby interpreter.  ( Used in ruby_exec() )
--   FMTP_CMD: (Linux only) The command used for reformatting paragraphs. ( Used in reformat_paragraph() )
module('modules.scite.editing', package.seeall)

-- platform specific options
local PLATFORM = _G.PLATFORM or 'linux'
local FILE_IN, FILE_OUT, REDIRECT, RUBY_CMD, FMTP_CMD
if PLATFORM == 'linux' then
  FILE_IN  = '/tmp/scite_input'
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' &> '
  RUBY_CMD = 'ruby '
  FMTP_CMD = 'fmt -c -w 80 '
elseif PLATFORM == 'windows' then
  FILE_IN  = os.getenv('TEMP')..'\\scite_input.rb'
  FILE_OUT = os.getenv('TEMP')..'\\scite_output.txt'
  REDIRECT = ' > '
  RUBY_CMD = 'ruby '
end
-- end options

---
-- [Local table] The kill-ring.
-- @class table
-- @name kill_ring
-- @field maxn The maximum size of the kill-ring.
local kill_ring = { pos = 1, maxn = 10 }

---
-- [Local table] Character matching.
-- Matches parentheses, brackets, braces, and quotes.
-- @class table
-- @name char_matches
local char_matches = {
  ['('] = ')', ['['] = ']', ['{'] = '}',
  ["'"] = "'", ['"'] = '"'
}

---
-- [Local table] Enclosures for enclosing or selecting ranges of text.
-- Note chars and tag enclosures are generated at runtime.
-- @class table
-- @name enclosure
local enclosure = {
  dbl_quotes = { left = '"', right = '"' },
  sng_quotes = { left = "'", right = "'" },
  parens     = { left = '(', right = ')' },
  brackets   = { left = '[', right = ']' },
  braces     = { left = '{', right = '}' },
  chars      = { left = ' ', right = ' ' },
  tags       = { left = '>', right = '<' },
  tag        = { left = ' ', right = ' ' },
  single_tag = { left = '<', right = ' />' }
}

---
-- SciTE Lua OnChar extension function.
-- Matches characters specified in char_matches if the editor pane has focus.
function _G.OnChar(c)
  if char_matches[c] and editor.Focus then
    editor:InsertText( -1, char_matches[c] )
  end
end

-- local functions
local insert_into_kill_ring, scroll_kill_ring
local get_preceding_number, get_sel_or_line

---
-- Cuts or copies text ranges intelligently. (Behaves like Emacs.)
-- If no text is selected, all text from the cursor to the end of the line is
-- cut or copied as indicated by action and pushed onto the kill-ring. If there
-- is text selected, it is cut or copied and pushed onto the kill-ring.
-- @param action The action to perform. Cut is done by default. 'copy' copies
--   text instead.
-- @see insert_into_kill_ring
function smart_cutcopy(action)
  local txt = editor:GetSelText()
  if #txt == 0 then editor:LineEndExtend() end
  txt = editor:GetSelText()
  insert_into_kill_ring(txt)
  kill_ring.pos = 1
  if action ~= 'copy' then editor:Cut() return end
  editor:Copy()
end

---
-- Retrieves the top item off the kill-ring and pastes it.
-- If an action is specified, the text is kept selected for scrolling through
-- the kill-ring.
-- @param action If given, specifies whether to cycle through the kill-ring in
--   normal or reverse order. A value of 'cycle' cycles through normally,
--   'reverse' in reverse.
-- @see scroll_kill_ring
function smart_paste(action)
  local anchor, pos = editor.Anchor, editor.CurrentPos
  if pos < anchor then anchor = pos end
  local txt = editor:GetSelText()
  if txt == kill_ring[kill_ring.pos] then scroll_kill_ring(action) end

  if scite.GetClipboardText then
    -- If text was copied to the clipboard from other apps, insert it into the
    -- kill-ring so it can be pasted (thanks to Nathan Robinson).
    local clip_txt, found = scite.GetClipboardText(), false
    if clip_txt ~= '' then
      for _, ring_txt in ipairs(kill_ring) do
        if clip_txt == ring_txt then found = true break end
      end
    end
    if not found then insert_into_kill_ring(clip_txt) end
  end

  txt = kill_ring[kill_ring.pos]
  if txt then
    editor:ReplaceSel(txt)
    if action then editor.Anchor = anchor end -- cycle
  end
end

---
-- Selects the current word under the caret and if action indicates, delete it.
-- @param action Optional action to perform with selected word. If 'delete', it
--   is deleted.
function current_word(action)
  local s = editor:WordStartPosition(editor.CurrentPos)
  local e = editor:WordEndPosition(editor.CurrentPos)
  editor:SetSel(s, e)
  if action == 'delete' then editor:DeleteBack() end
end

---
-- Transposes characters intelligently.
-- If the carat is at the end of the current word, the two characters before
-- the caret are transposed. Otherwise the characters to the left and right of
-- the caret are transposed.
function transpose_chars()
  editor:BeginUndoAction()
  local pos  = editor.CurrentPos
  local char = editor.CharAt[pos - 1]
  editor:DeleteBack()
  if pos > editor.Length or editor.CharAt[pos - 1] == 32 then
    editor:CharLeft()
  else
    editor:CharRight()
  end
  editor:InsertText( -1, string.char(char) )
  editor:SetSel(pos, pos)
  editor:EndUndoAction()
end

---
-- Reduces multiple characters occurances to just one.
-- If char is not given, the character to be squeezed is the one under the
-- caret.
-- @param char The character to be used for squeezing.
function squeeze(char)
  if not char then char = editor.CharAt[editor.CurrentPos - 1] end
  local s, e = editor.CurrentPos - 1, editor.CurrentPos - 1
  while editor.CharAt[s] == char do s = s - 1 end
  while editor.CharAt[e] == char do e = e + 1 end
  editor:SetSel(s + 1, e)
  editor:ReplaceSel( string.char(char) )
end

---
-- Joins the current line with the line below, eliminating whitespace.
function join_lines()
  editor:BeginUndoAction()
  editor:LineEnd() editor:Clear() editor:AddText(' ') squeeze()
  editor:EndUndoAction()
end

---
-- Moves the current line in the specified direction up or down.
-- @param direction 'up' moves the current line up, 'down' moves it down.
function move_line(direction)
  local column = editor.Column[editor.CurrentPos]
  editor:BeginUndoAction()
  if direction == 'up' then
    editor:LineTranspose()
    editor:LineUp()
  elseif direction == 'down' then
    editor:LineDown()
    editor:LineTranspose()
    column = editor.CurrentPos + column -- starts at line home
    editor:SetSel(column, column)
  end
  editor:EndUndoAction()
end

---
-- Encloses text in an enclosure set.
-- If text is selected, it is enclosed. Otherwise, the previous word is
-- enclosed. The n previous words can be enclosed by appending n (a number) to
-- the end of the last word. When enclosing with a character, append the
-- character to the end of the word(s). To enclose previous word(s) with n
-- characters, append n (a number) to the end of character set.
-- Examples:
--   enclose this2 -> 'enclose this' (enclose in sng_quotes)
--   enclose this2**2 -> **enclose this**
-- @param str The enclosure type in enclosure.
-- @see enclosure
-- @see get_preceding_number
function enclose(str)
  editor:BeginUndoAction()
  local txt = editor:GetSelText()
  if txt == '' then
    if str == 'chars' then
      local num_chars, len_num_chars = get_preceding_number()
      for i = 1, len_num_chars do editor:DeleteBack() end
      for i = 1, num_chars do editor:CharLeftExtend() end
      enclosure[str].left  = editor:GetSelText()
      enclosure[str].right = enclosure[str].left
      editor:DeleteBack()
    end
    local num_words, len_num_chars = get_preceding_number()
    for i = 1, len_num_chars do editor:DeleteBack() end
    for i = 1, num_words do editor:WordLeftExtend() end
    txt = editor:GetSelText()
  end
  local len = 0
  if str == 'tag' then
    enclosure[str].left  = '<'..txt..'>'
    enclosure[str].right = '</'..txt..'>'
    len = #txt + 3
    txt = ''
  end
  local left  = enclosure[str].left
  local right = enclosure[str].right
  editor:ReplaceSel(left..txt..right)
  if str == 'tag' then editor:GotoPos(editor.CurrentPos - len) end
  editor:EndUndoAction()
end

---
-- Selects text in a specified enclosure.
-- @param str The enclosure type in enclosure. If str is not specified,
--   matching character pairs defined in char_matches are searched for from the
--   caret outwards.
-- @see enclosure
-- @see char_matches
function select_enclosed(str)
  if str then
    editor:SearchAnchor(editor.CurrentPos)
    local s = editor:SearchPrev( 0, enclosure[str].left )
    local e = editor:SearchNext( 0, enclosure[str].right )
    if s and e then editor:SetSel(s + 1, e) end
  else
    -- TODO: ignore enclosures in comment scopes?
    s, e = editor.Anchor, editor.CurrentPos
    if s > e then s, e = e, s end
    local char = string.char( editor.CharAt[s - 1] )
    if s ~= e and char_matches[char] then
      s, e = s - 2, e + 1 -- don't match the same enclosure
    end
    while s >= 0 do
      char = string.char( editor.CharAt[s] )
      if char_matches[char] then
        local _, e = editor:findtext( char_matches[char], 0, e )
        if e then editor:SetSel(s + 1, e - 1) break end
      end
      s = s - 1
    end
  end
end

---
-- Selects the current line.
function select_line() editor:Home() editor:LineEndExtend() end

---
-- Selects the current paragraph.
-- Paragraphs are delimited by two consecutive newlines.
function select_paragraph() editor:ParaUp() editor:ParaDownExtend() end

---
-- Selects indented blocks intelligently.
-- If no block of text is selected, all text with the current level of
-- indentation is selected. If a block of text is selected and the lines to the
-- top and bottom of it are one indentation level lower, they are added to the
-- selection. In all other cases, the behavior is the same as if no text is
-- selected.
function select_indented_block()
  local s = editor:LineFromPosition(editor.Anchor)
  local e = editor:LineFromPosition(editor.CurrentPos)
  if s > e then s, e = e, s end
  local indent = editor.LineIndentation[s] - editor.Indent
  if indent < 0 then return end
  if editor:GetSelText() ~= '' then
    if editor.LineIndentation[s - 1] == indent and
      editor.LineIndentation[e + 1] == indent then
      s, e = s - 1, e + 1
      indent = indent + editor.Indent -- don't run while loops
    end
  end
  while editor.LineIndentation[s - 1] > indent do s = s - 1 end
  while editor.LineIndentation[e + 1] > indent do e = e + 1 end
  s = editor:PositionFromLine(s)
  e = editor.LineEndPosition[e]
  editor:SetSel(s, e)
end

---
-- Selects all text with the same scope/style as under the caret.
function select_scope()
  local start_pos = editor.CurrentPos
  local base_style = editor.StyleAt[start_pos]
  local pos = start_pos - 1
  while editor.StyleAt[pos] == base_style do pos = pos - 1 end
  local start_style = pos
  pos = start_pos + 1
  while editor.StyleAt[pos] == base_style do pos = pos + 1 end
  editor:SetSel(start_style + 1, pos)
end

---
-- Executes the selection or contents of the current line as Ruby code,
-- replacing the text with the output.
function ruby_exec()
  local txt = get_sel_or_line()
  local f, out
  -- write the file
  f = io.open(FILE_IN, 'w') f:write(txt) f:close()
  -- check the syntax
  os.execute(RUBY_CMD..'-cw '..FILE_IN..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  -- execute the file
  if out == 'Syntax OK\n' then
    os.execute(RUBY_CMD..FILE_IN..REDIRECT..FILE_OUT)
    f = io.open(FILE_OUT) out = f:read('*all') f:close()
    if out:sub(-1) == '\n' then out = out:sub(1, -2) end
  end
  editor:ReplaceSel(out)
end

---
-- Executes the selection or contents of the current line as Lua code,
-- replacing the text with the output.
function lua_exec()
  local txt = get_sel_or_line()
  dostring(txt)
  editor:SetSel(editor.CurrentPos, editor.CurrentPos)
end

---
-- Reformats the selected text or current paragraph using the command FMTP_CMD.
function reformat_paragraph()
  if PLATFORM ~= 'linux' then print('Linux only') return end
  if editor:GetSelText() == '' then select_paragraph() end
  local txt = editor:GetSelText()
  local f, out
  f = io.open(FILE_IN, 'w') f:write(txt) f:close()
  os.execute(FMTP_CMD..FILE_IN..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  if txt:sub(-1) ~= '\n' and out:sub(-1) == '\n' then out = out:sub(1, -2) end
  editor:ReplaceSel(out)
end

--[[
---
-- Jumps to a buffer and location specified by a CTag selected or on the
-- current line.
function goto_ctag()
  local line = get_sel_or_line()
  local s1, s2, tag_name, file_name, tag_pattern =
        string.find(line, '([^\t]*)\t([^\t]*)\t(.*)$')
  if file_name == nil then return end
  scite.Open(file_name)
  s1 = string.find(tag_pattern, '$/')
  if s1 ~= nil then
    tag_pattern = string.sub(tag_pattern, 3, s1 - 1)
    tag_pattern = string.gsub(tag_pattern, '\\/', '/')
    local p1, p2 = editor:findtext(tag_pattern)
    if p2 then editor:SetSel(p1, p2) end
  else -- line numbers
    s1 = string.find(tag_pattern, ';')
    tag_pattern = string.sub(tag_pattern, 0, s1 - 1)
    local tag_line = tonumber(tag_pattern) - 1
    editor:GotoLine(tag_line)
  end
  local fline = editor.FirstVisibleLine
  local cline = editor:LineFromPosition(editor.CurrentPos)
  editor:LineScroll(0, cline - fline)
end
]]--

---
-- [Local function] Inserts text into kill_ring.
-- If it grows larger than maxn, the oldest inserted text is replaced.
-- @see smart_cutcopy
insert_into_kill_ring = function(txt)
  table.insert(kill_ring, 1, txt)
  local maxn = kill_ring.maxn
  if #kill_ring > maxn then kill_ring[maxn + 1] = nil end
end

---
-- [Local function] Scrolls kill_ring in the specified direction.
-- @param direction The direction to scroll: 'forward' (default) or 'reverse'.
-- @see smart_paste
scroll_kill_ring = function(direction)
  if direction == 'reverse' then
    kill_ring.pos = kill_ring.pos - 1
    if kill_ring.pos < 1 then kill_ring.pos = #kill_ring end
  else
    kill_ring.pos = kill_ring.pos + 1
    if kill_ring.pos > #kill_ring then kill_ring.pos = 1 end
  end
end

---
-- [Local function] Returns the number to the left of the caret.
-- This is used for the enclose function.
-- @see enclose
get_preceding_number = function()
  local pos = editor.CurrentPos
  local char = editor.CharAt[pos - 1]
  local txt = ''
  while tonumber( string.char(char) ) do
    txt = txt..string.char(char)
    pos = pos - 1
    char = editor.CharAt[pos - 1]
  end
  return tonumber(txt) or 1, #txt
end

---
-- [Local function] Returns the current selection or the contents of the
-- current line.
get_sel_or_line = function()
  if editor:GetSelText() == '' then select_line() end
  return editor:GetSelText()
end
