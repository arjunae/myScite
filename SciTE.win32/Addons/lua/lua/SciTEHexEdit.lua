-----------------------------------------------------------------------
-- SciTEHexEdit: A Self-Contained Primitive Hex Editor for SciTE
------------------------------------------------------------------------
-- Copyright 2005-2006 by Kein-Hong Man <khman@users.sf.net>
--
local VERSION, REVDATE = "0.11", "20061027"     -- version information
--
-- See SciTEHexEdit.txt for usage instructions.
-- Development platform: WinXP SciTE 1.71 (Mingw)
------------------------------------------------------------------------
-- Permission to use, copy, modify, and distribute this software and
-- its documentation for any purpose and without fee is hereby granted,
-- provided that the above copyright notice appear in all copies and
-- that both that copyright notice and this permission notice appear
-- in supporting documentation.
--
-- KEIN-HONG MAN DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
-- INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN
-- NO EVENT SHALL KEIN-HONG MAN BE LIABLE FOR ANY SPECIAL, INDIRECT OR
-- CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
-- OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
-- NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
-- WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
------------------------------------------------------------------------
-- QUICKSTART
-- * Load this script and call HexEditor() or HexEditorNew()
------------------------------------------------------------------------
-- TODO
-- * Improve file size limit warning. What is the best approach?
-- * Search and replace function. This may change the file size.
-- * Allow file size change, e.g. append new data to end of a file.
-- * Parameter window to open a file in hex mode.
-- * Undo and redo, might be possible to use < and >.
-- * Load-on-demand may be better than loading everything in at once.
-- * Console string arguments currently has a simple escape mechanism.
-- * Will probably fail with multi-byte character sets
------------------------------------------------------------------------
-- TECHNICAL NOTES
-- * For safety, a backup file is always created.
-- * Up-down movement can sometimes jump columns, hard to fix perfectly.
-- * Error message display to console/output window still a bit messy.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- constants and primitives
------------------------------------------------------------------------
local SIZELIMIT = 100                   -- maximum size allowable (bytes)
local BLOCKSIZE = 1048576               --   = SIZELIMIT * BLOCKSIZE

local PAGESIZE = 256                    -- # of bytes on screen at once
local PAGE1K = 1024                     -- # of bytes for bigger jumps

local NONPRINTING = 32                  -- ASCII substitute for control chars
local MONOSPACE = nil                   -- monospace property override
                                        -- e.g. "font:Courier New,size:10"
local CONSOLEPROMPT = "> "              -- default console prompt

local STRINGSPAT = "[%s%w%p]+%z"        -- matcher for strings command
local STRINGSMIN = 4                    -- minimum strings length (filtering)
local STRINGSMAX = 80                   -- maximum strings length (truncation)

local SIG = "SciTEHexEdit"
local string, math, table = string, math, table

local MSG = {                           -- mostly textual data
------------------------------------------------------------------------
-- edit window elements
-- TODO: R (Replace)    replace <info> <data>
--       Search and replace. Replacement can either be a
--       literal string (single quotes) or a hex number.
------------------------------------------------------------------------
  Header = [[
. SciTE Hex Editor . ver VERSION . REVDATE .
]],
  Footer = [[
|    / (FirstPg) [ (Prev1K) - (PrevPg) + (NextPg) ] (Next1K) * (LastPg)     |
|    . or ` (Console Mode) N (Find Next) H (Help Screen)                    |
]],
  FootWinLn = [[
+--------------------------------------------------------------------+
]],
  Buttons = [[
| Refresh | Revert | FirstPg | PrevPg | NextPg | LastPg | Console | Help |
]],
  ButtonLn = 2,
  EditWinLn = [[
+--------+-------------------------------------------------+----------------+
]],
  EditLegend = [[
| Offset | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F |   ASCII view   |
]],
------------------------------------------------------------------------
-- help messages (MSG.Help.<id> where <id> can be console commands)
-- * console and help mode are in diff syntax highlighting style
------------------------------------------------------------------------
  Help = {
    help = [[

Enter "help console" for a summary of console commands, "help edit" for
edit window help, or "help <cmd>" (where <cmd> is a console command) for
help on using a particular command. The available console commands are:

  cls  info  goto  load  save  revert  search  number  help  exit

]],
------------------------------------------------------------------------
    about = [[

--- About the SciTE Hex Editor ---

Many thanks to Andre Carregal and the LuaForge team.
SciTEHexEdit is hosted by LuaForge at:
 http://luaforge.net/projects/sl-hexedit/
SciTEHexEdit was written by Kein-Hong Man <khman@users.sf.net>,
and is distributed under an MIT-style Open Source license.
Lots more Lua scripts can be found at the community wiki site at:
 http://lua-users.org/wiki/SciteScripts

]],
------------------------------------------------------------------------
    console = [[

--- SciTE Hex Editor Console ---

Enter single commands at prompt line only. Most commands closes the
console window on successful execution. Adding a "-" as a suffix will
stop the console window from closing, e.g. "save-". Commands (which
are case insensitive) are:

  cls                           goto <dec|hex>
  info                          load <filename>
  revert                        save|saveas [<filename>]
  float <float|hex>             number <dec|hex|"string">
  strings                       search <hex|'string'|"regexp">
  exit|close                    help help|about|console|edit|<cmd>

]],
------------------------------------------------------------------------
    edit = [[

--- Edit Window Help ---

Keypress navigation is recommended. Double-click "buttons" or press
[Space] with the caret on the desired button. Use the console window,
accessed using a period (.) or a backtick (`), for other commands. See
the bottom of the edit window for keypress commands. Also, [Enter]
moves one line down in the edit columns, and [Space] moves the caret
to the next byte in the hex data column.

SciTEHexEdit starts by: (1) loading the file in the current buffer,
ignoring unsaved changes, or (2) using the contents of the untitled
and unsaved buffer. The edit view is automatically positioned where
the caret was in the current buffer.

- Offset column:
Pressing a valid digit changes the address of the page in view, and
the editor will jump to the block in question.

- Hex data column:
Pressing a valid digit changes data in the file. To make the changes
permanent, save the file. Use "revert" to undo.

- ASCII data column:
Pressing a character changes data in the file. Changes can then be
saved or dropped. Not all characters can be entered, because some
keypresses are handled only by SciTE itself.

Data is colour-coded. Unsaved changes are highlighted in yellow. To
customize SciTEHexEdit further, please modify the Lua script itself.

@ Press H again to return to the previous screen...]],
------------------------------------------------------------------------
-- help messages for commands
------------------------------------------------------------------------
    cls = [[

  cls

Resets the console window view to its start condition. Does not close
the console window.

]],
------------------------------------------------------------------------
    info = [[

  info

Displays some information about the current file. Does not close the
console window.

]],
------------------------------------------------------------------------
    goto = [[

  goto <dec|hex>

Jumps to a given position, closing the console window in the process.
To avoid closing the console window, use "goto-" instead of "goto".
E.g. goto 1234, goto 0x200

]],
------------------------------------------------------------------------
    load = [[

  load <filename>

Loads a file. The file being edited must be empty, unchanged, or
changes have been saved. The console window is automatically closed.
To avoid closing the console window, use "load-" instead of "load".
E.g. load foo.txt, load "misc/my notes.txt"

]],
------------------------------------------------------------------------
    save = [[

  save|saveas [<filename>]

Saves the current file, closing the console window in the process. If
no filename is specified, the current filename is used. If a filename
is specified, the data will take on the new name. The command "saveas"
is an alias for "save". To avoid closing the console window, use
"save-" instead of "save".
E.g. save, save "bar.txt", saveas "baz.txt"

]],
------------------------------------------------------------------------
    revert = [[

  revert

If the data is from a file, the file is reloaded and all unsaved
changes will be lost. If the data is from an untitled buffer, the
original data is restored. No warning is given if there are still
unsaved changes. The console window is automatically closed. To avoid
closing the console window, use "revert-" instead of "revert".

]],
------------------------------------------------------------------------
    search = [[

  search <hex|'string'|"regexp">

Search for some data. If the data is found, the console window is
closed and the edit view jumps to the start of the matched data. To
find further matches, press N ("Find Next") in the edit window. To
avoid closing the console window, use "search-" instead of "search".

Literal search data can be specified as a hex digit string or a
character string enclosed in single quotes. To search using regular
expressions, use Lua-style regular expressions in double quotes.
E.g. search 0xDEADBEEF, search 'FOO', search "^The%s"

]],
------------------------------------------------------------------------
    number = [[

  number <dec|hex|"string">

A general type conversion function. Comverts a decimal number, a hex
number, or a string into other data types. Does not close the console
window.
E.g. number 0xDEADBEEF, number 65535, number "foobar"

]],
------------------------------------------------------------------------
    float = [[

  float <float|hex>

Converts a little-endian hex sequence to a single- or double-precision
number, depending on the length of the hex sequence. Does not close the
console window. If the argument is a regular number, it is converted
into both little-endian single (if the numer is in range) and double
precision hex data. The command also recognizes the following special
names: INF, INF+, INF-
E.g. float 0x11111111, float 12.34e56, float INF+

]],
------------------------------------------------------------------------
    strings = [[

  strings

Extracts strings from binary data, often an executable or an object
file. Data must contain NULs (ASCII 0) or else the command is aborted.
Only ASCII strings of 4 to 80 bytes are shown (these settings can be
changed in the script.) The command does not close the console window.

]],
------------------------------------------------------------------------
    help = [[

  help help|about|console|edit|<cmd>

Displays help texts. For "help edit" help, the view switches to a help
view; pressing H returns the user to the original view mode.

]],
------------------------------------------------------------------------
    exit = [[

  exit|close

Exits this console mode and returns to the edit window. "close" is an
alias.

]],
  },
------------------------------------------------------------------------
}

------------------------------------------------------------------------
-- user interface data
------------------------------------------------------------------------

local KeyMap = {                        -- keymap translation
  ["+"] = "NextPg", ["-"] = "PrevPg",
  ["]"] = "Next1K", ["["] = "Prev1K",
  ["/"] = "FirstPg", ["*"] = "LastPg",
  ["."] = "Console", ["`"] = "Console",
  ["H"] = "Help", ["h"] = "Help",
  ["N"] = "FindNext", ["n"] = "FindNext",
--TODO  ["R"] = "Replace", ["r"] = "Replace",
}

local WIN = {                           -- window has fixed bounds
  POS = { x1 =  2, y1 = 7, x2 =  9, y2 = 22, },
  HEX = { x1 = 11, y1 = 7, x2 = 59, y2 = 22, },
  ASC = { x1 = 61, y1 = 7, x2 = 76, y2 = 22, },
}

------------------------------------------------------------------------
-- colour scheme for windows and character set colour coding
-- * possible properties: Back, Bold, Case, EOLFilled, Font, Fore,
--   Italic, Size, Underline, Visible (and possibly more...)
------------------------------------------------------------------------

-- for edit window
local ColourScheme = {
  [ 8] = {Fore = "987678", Bold = true},        -- title
  [16] = {Fore = "800000",},                    -- button bar
  [17] = {Fore = "456733", Back = "800000"},    -- button text
  [18] = {Fore = "987678", Bold = true},        -- edit box header
  [19] = {Fore = "206090"},                     -- position pane
  [20] = {Fore = "808000",},                    -- information box
  [21] = {Fore = "808000", Bold = true},        -- save file info
  -- data highlighting, unchanged
  [ 1] = {Fore = "DC2300",},                    -- control chars
  [ 2] = {Fore = "333399",},                    -- symbols
  [ 3] = {Fore = "008080",},                    -- numbers
  [ 4] = {Fore = "987678",},                    -- alphabets
  [ 5] = {Fore = "008000",},                    -- extended chars
  [ 6] = {Fore = "C0C0C0",},                    -- past-EOF
  [ 7] = {Fore = "987678",},                    -- ASCII pane
  -- data highlighting, changed
  [ 9] = {Fore = "DC2300", Back = "FFFF00"},    -- control chars
  [10] = {Fore = "333399", Back = "FFFF00"},    -- symbols
  [11] = {Fore = "008080", Back = "FFFF00"},    -- numbers
  [12] = {Fore = "987678", Back = "FFFF00"},    -- alphabets
  [13] = {Fore = "008000", Back = "FFFF00"},    -- extended chars
  [14] = {Fore = "C0C0C0", Back = "FFFF00"},    -- past-EOF
  [15] = {Fore = "987678", Back = "FFFF00"},    -- ASCII pane
}

-- byte value colour coding
local CharColours = {   -- {<from_code>,<to_code>,<style>},
  {  0,  31, 1},        -- control chars
  { 32,  47, 2},        -- symbols
  { 48,  57, 3},        -- numbers
  { 58,  64, 2},        -- symbols
  { 65,  90, 4},        -- alphabets
  { 91,  96, 2},        -- symbols
  { 97, 122, 4},        -- alphabets
  {123, 127, 2},        -- symbols
  {128, 255, 5},        -- extended chars
}

-- for console window and help window (diff styling in parentheses)
local ColourSchemeDiff = {
  [ 1] = {Fore = "007F00",},                    -- generic (comment)
  [ 2] = {Fore = "7F7F00",},                    -- (command)
  [ 3] = {Fore = "7F0000", Bold = true},        -- titles (filespec)
  [ 4] = {Fore = "DC2300",},                    -- errors (position)
  [ 5] = {Fore = "007F7F",},                    -- (deletion)
  [ 6] = {Fore = "0000BF",},                    -- prompt (addition)
}

------------------------------------------------------------------------
-- simple check for extman, partially emulate if okay to do so
------------------------------------------------------------------------
local function Error(msg) _ALERT(">"..SIG..": "..msg) end   -- error msg

if (OnDoubleClick or OnChar or OnSwitchFile) and not scite_Command then
  Error("There is a handler conflict, please use extman")
else
  -- simple way to add a handler only, can't remove like extman does
  if not scite_OnDoubleClick then
    local _OnDC
    scite_OnDoubleClick = function(f) _OnDC = f end
    OnDoubleClick = function(c) if _OnDC then return _OnDC(c) end end
  end
  if not scite_OnChar then
    local _OnCh
    scite_OnChar = function(f) _OnCh = f end
    OnChar = function(c) if _OnCh then return _OnCh(c) end end
  end
  if not scite_OnSwitchFile then
    local _OnSF
    scite_OnSwitchFile = function(f) _OnSF = f end
    OnSwitchFile = function(c) if _OnSF then return _OnSF(c) end end
  end
end

------------------------------------------------------------------------
-- preprocessing of window and style elements
------------------------------------------------------------------------
local Buttons = {}
local StyleMono = {}

local function WindowSetup()
  MSG.Help.saveas = MSG.Help.save               -- help aliases
  MSG.Help.close = MSG.Help.exit
  --------------------------------------------------------------------
  MSG.Header = string.gsub(MSG.Header, "REVDATE", REVDATE)
  MSG.Header = string.gsub(MSG.Header, "VERSION", VERSION)
  --------------------------------------------------------------------
  local ln = string.gsub(MSG.Buttons, "|", "+") -- autogen box lines
  MSG.Butln = string.gsub(ln, "[^+\r\n]", "-")
  local _, ln = string.find(MSG.Footer, "[^\r\n]+")
  MSG.FootWinSz = ln or 2
  MSG.FootWinLn = "+"..string.rep("-", MSG.FootWinSz - 2).."+\n"
  --------------------------------------------------------------------
  local i = 1                                   -- get button information
  while true do
    local x1, x2, name = string.find(MSG.Buttons, "|%s+([^|]+)%s+|", i)
    if not x1 then break end
    local entry = {x1+1, x2-1, name}
    table.insert(Buttons, entry)
    i = x1 + 1
  end
  --------------------------------------------------------------------
  local cc = {}                                 -- charset colour table
  for i,v in ipairs(CharColours) do
    local s = string.char(v[3])
    for c = v[1], v[2] do table.insert(cc, s) end
  end
  cc = table.concat(cc)
  if string.len(cc) ~= 256 then
    Error("Character set colour scheme incomplete, check CharColours")
    cc = string.rep(" ", 256)                   -- style 32
  end
  buffer.CharColours = cc
  --------------------------------------------------------------------
  local monoprop =  props["font.monospace"]    
  -- get monospace style
                   
  for style, value in string.gfind(monoprop, "([^,:]+):([^,]+)") do
    StyleMono[style] = value
  end
  --------------------------------------------------------------------
end

------------------------------------------------------------------------
-- set colour scheme of hex editor from a table
------------------------------------------------------------------------
local function SetColours(lexer, scheme)
  local function dec(s) return tonumber(s, 16) end
  local monoFont, monoSize = StyleMono.font, StyleMono.size
  editor.Lexer = lexer
  --------------------------------------------------------------------
  editor:StyleClearAll()
  for i = 0, 127 do                             -- force mono first
    editor.StyleFont[i] = monoFont
    editor.StyleSize[i] = monoSize
  end
  --------------------------------------------------------------------
  if not scheme then return end
  for i, style in pairs(scheme) do              -- set up scheme
    for prop, value in pairs(style) do
      if (prop == "Fore" or prop == "Back")
         and type(value) == "string" then -- convert from string
        local hex, hex, r, g, b =
          string.find(value, "^(%x%x)(%x%x)(%x%x)$")
        value = hex and (dec(r) + dec(g)*256 + dec(b)*65536) or 0
      end
      editor["Style"..prop][i] = value
    end--each property
  end--each style
end

------------------------------------------------------------------------
-- functions for IEEE 754 float and double conversion
------------------------------------------------------------------------

-- IEEE 32-bit single precision to little endian char string
local function single2hex(x)
  local function grab(v)
    return math.floor(v / 256), string.format("%02X", math.mod(v, 256))
  end
  local sign = 0; if x < 0 then sign = 1; x = -x end
  local mantissa, exponent = math.frexp(x)
  if x == 0 then -- zero
    mantissa, exponent = 0, 0
  elseif x == 1/0 then -- infinity
    mantissa, exponent = 0, 255
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
    exponent = exponent + 126
  end
  local v, x, c = "0x", mantissa -- convert to bytes
  x, c = grab(mantissa); v = v..c -- 7:0
  x, c = grab(x); v = v..c -- 15:8
  x, c = grab(exponent * 128 + x); v = v..c -- 23:16
  x, c = grab(sign * 128 + x); v = v..c -- 31:24
  return v
end

-- IEEE 64-bit double precision to little endian char string
local function double2hex(x)
  local function grab(v)
    return math.floor(v / 256), string.format("%02X", math.mod(v, 256))
  end
  local sign = 0; if x < 0 then sign = 1; x = -x end
  local mantissa, exponent = math.frexp(x)
  if x == 0 then -- zero
    mantissa, exponent = 0, 0
  elseif x == 1/0 then -- infinity
    mantissa, exponent = 0, 2047
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
    exponent = exponent + 1022
  end
  local v, x, c = "0x", mantissa -- convert to bytes
  for i = 1,6 do x, c = grab(x); v = v..c end -- 47:0
  x, c = grab(exponent * 16 + x); v = v..c -- 55:48
  x, c = grab(sign * 128 + x); v = v..c -- 63:56
  return v
end

-- little endian char string to IEEE 32-bit single precision
local function hex2single(x)
  local sign, signc = 1, "+"
  local mantissa = math.mod(x[3], 128)
  for i = 2, 1, -1 do mantissa = mantissa * 256 + x[i] end
  if x[4] > 127 then
    sign, signc = -1, "-"
  end
  local exponent = math.mod(x[4], 128) * 2 + math.floor(x[3] / 128)
  if exponent == 0 then
    if mantissa ~= 0 then return "Denormal"..signc end
    return 0
  elseif exponent == 255 then
    if mantissa ~= 0 then return "NaN"..signc end
    return "Infinity"..signc
  end
  mantissa = (math.ldexp(mantissa, -23) + 1) * sign
  return math.ldexp(mantissa, exponent - 127)
end

-- little endian char string to IEEE 64-bit double precision
local function hex2double(x)
  local sign, signc = 1, "+"
  local mantissa = math.mod(x[7], 16)
  for i = 6, 1, -1 do mantissa = mantissa * 256 + x[i] end
  if x[8] > 127 then
    sign, signc = -1, "-"
  end
  local exponent = math.mod(x[8], 128) * 16 + math.floor(x[7] / 16)
  if exponent == 0 then
    if mantissa ~= 0 then return "Denormal"..signc end
    return 0
  elseif exponent == 255 then
    if mantissa ~= 0 then return "NaN"..signc end
    return "Infinity"..signc
  end
  mantissa = (math.ldexp(mantissa, -52) + 1) * sign
  return math.ldexp(mantissa, exponent - 1023)
end

------------------------------------------------------------------------
-- some functions for operating editor
------------------------------------------------------------------------

-- shorthand for directing command error messages
local function CmdError(msg)
  if buffer.AutoClose then Error(msg)
  else editor:AddText("@ "..msg.."\n")  -- @ for styling in diff lexer
  end
end

-- align a number to a 2^n value
local function Align(n, width)
  if not width then width = 16 end
  return n - math.mod(n, width)
end

-- move to data position in hex window
local function MoveToHex(i)
  local x = math.mod(i, 16)
  local y = (i - x) / 16 + WIN.HEX.y1
  x = x * 3 + WIN.HEX.x1
  i = editor:FindColumn(y, x)
  editor:GotoPos(i)
end

-- move to data position in ascii window
local function MoveToAscii(i)
  local x = math.mod(i, 16)
  local y = (i - x) / 16 + WIN.ASC.y1
  if x == 0 then x = x - 1 end
  x = x + WIN.ASC.x1
  i = editor:FindColumn(y, x)
  editor:GotoPos(i)
end

-- check for hex numbers
local function IsHex(s)
  if string.find(s, "^0[xX](%x+)$") then return tonumber(s, 16) end
end

-- check for decimal numbers
local function IsDec(s)
  if string.find(s, "^%d+$") then return tonumber(s) end
end

-- check for single quote strings
local function IsQuote1(s)
  local q = string.sub(s, 1, 1)..string.sub(s, -1, -1)
  if q == [['']] and string.len(s) > 2 then
    return string.sub(s, 2, -2)
  end
end

-- check for double quote strings
local function IsQuote2(s)
  local q = string.sub(s, 1, 1)..string.sub(s, -1, -1)
  if q == [[""]] and string.len(s) > 2 then
    return string.sub(s, 2, -2)
  end
end

-- allow only a number of arguments, one by default
local function CheckForArg(args, min, max)
  if not min then min, max = 1, 1
  elseif not max then max = min
  end
  local n = table.getn(args)
  if n < min or n > max then
    CmdError("Incorrect number of arguments, please check the documentation")
    return true
  end
end

-- get a byte value in data, returns 0 if out of range
local function GetByte(off)
  if off >= buffer.DataSz then return 0 end
  return string.byte(buffer.Data, off + 1)
end

-- set a byte in data, fails silently if out of range
local function SetByte(off, byte)
  if off >= buffer.DataSz then return end
  local d = buffer.Data
  buffer.Data = string.sub(d, 1, off)..string.char(byte)..string.sub(d, off+2)
  buffer.Edited = true
  return true
end

-- mark a byte as edited, 0<=1<=255
local function MarkAsEdited(off)
  local i = math.mod(off, PAGESIZE)
  local page = (off - i) / PAGESIZE
  local p = buffer.ChangeSet[page]
  if not p then p = string.rep("\0", PAGESIZE) end
  buffer.ChangeSet[page] = string.sub(p, 1, i).."\1"..string.sub(p, i+2)
end

------------------------------------------------------------------------
-- file I/O functions
------------------------------------------------------------------------

------------------------------------------------------------------------
-- basic data loader with size limit
------------------------------------------------------------------------
local function LoadData(filepath)
  local INF = io.open(filepath, "rb")
  if not INF then
    CmdError("Failed to open '"..filepath.."' for reading") return
  end
  local src, len = {}, 0
  while true do                         -- read with limit check
    local blk, err = INF:read(BLOCKSIZE)
    if not blk then
      if err then
        CmdError("Failed to read from '"..filepath.."'")
        io.close(INF) return
      end
      break
    end
    table.insert(src, blk)
    len = len + string.len(blk)
    if len > SIZELIMIT * BLOCKSIZE then
      CmdError("File too large, can't open, please adjust SIZELIMIT in script")
      io.close(INF) return
    end
  end--while
  io.close(INF)
  if len == 0 then src = "" else src = table.concat(src) end
  return src, len
end

------------------------------------------------------------------------
-- basic data saver with backup files
------------------------------------------------------------------------
local function SaveData(filepath, filedata)
  local TMPEXT = ".$$$"
  local INF = io.open(filepath, "rb")   -- look for existing file
  if INF then
    io.close(INF)
    local newname, n = filepath..TMPEXT, 1 -- rename routine
    while true do
      local okay = os.rename(filepath, newname)
      if okay then break end
      newname, n = filepath.."("..n..")"..TMPEXT, n + 1
      if n == 100 then
        CmdError("Failed to rename original, aborting save operation")
        return
      end
    end
  end
  local ONF = io.open(filepath, "wb")   -- write data to file
  if not ONF then
    CmdError("Failed to open '"..filepath.."' for writing") return
  end
  local okay = ONF:write(filedata)
  io.close(ONF)
  if okay then return true end
  CmdError("Failed to write data to '"..filepath.."'")
end

------------------------------------------------------------------------
-- implementation of some commands
------------------------------------------------------------------------

local Command = {
  --------------------------------------------------------------------
  -- help mode switching
  --------------------------------------------------------------------
  Help = function(args)
    if args == "edit" then
    elseif CheckForArg(args, 0, 1) then return
    else args = string.lower(args[1] or "help")
    end
    if args == "edit" then                      -- special edit help
      buffer.OldPos = editor.CurrentPos
      buffer.Mode = string.upper(buffer.Mode)
      buffer.Snapshot = editor:GetText()
      SetColours(SCLEX_DIFF, ColourSchemeDiff)
      return
    end
    local msg = MSG.Help[args] or CmdError("Unrecognized help argument")
    editor:AddText(msg)
  end,
  --------------------------------------------------------------------
  UnHelp = function()
    buffer.Mode = string.lower(buffer.Mode)
    if buffer.Mode ~= "console" then
      SetColours(SCLEX_CONTAINER, ColourScheme)
    end
    editor:SetText(buffer.Snapshot)
    editor:GotoPos(buffer.OldPos)
    if buffer.Mode == "console" then
      editor:AddText(CONSOLEPROMPT)
      editor:Colourise(0,-1)
    end
  end,
  --------------------------------------------------------------------
  -- console mode switching
  --------------------------------------------------------------------
  Console = function()
    buffer.EditPos = editor.CurrentPos
    buffer.EditWin = editor:GetText()
    buffer.Mode = "console"
    SetColours(SCLEX_DIFF, ColourSchemeDiff)
    editor:ClearAll()
    if not buffer.ConsoleWin then
      buffer.ConsoleWin = MSG.Help.console
    end
    editor:AddText(buffer.ConsoleWin..CONSOLEPROMPT)
    editor:DocumentEnd()
    editor:Colourise(0,-1)
  end,
  --------------------------------------------------------------------
  UnConsole = function()
    buffer.ConsoleWin = editor:GetText()
    local pos = buffer.EditPos
    buffer.Mode = "edit"
    SetColours(SCLEX_CONTAINER, ColourScheme)
    editor:SetText(buffer.EditWin)
    if type(pos) == "number" then
      editor:GotoPos(pos)
    else
      MoveToHex(tonumber(pos))          -- goto command needs delayed
    end                                 -- positioning of caret
  end,
  --------------------------------------------------------------------
  -- movement in editing window
  --------------------------------------------------------------------
  First = function()
    buffer.Offset = 0
  end,
  --------------------------------------------------------------------
  Last = function()
    buffer.Offset = Align(buffer.DataSz, PAGESIZE)
  end,
  --------------------------------------------------------------------
  Prev = function(PageSz)
    local i = buffer.Offset - PageSz
    buffer.Offset = (i >= 0) and i or 0
  end,
  --------------------------------------------------------------------
  Next = function(PageSz)
    local old = buffer.Offset
    local i = old + PageSz
    buffer.Offset = (i < buffer.DataSz) and i or
                    Align(buffer.DataSz, PAGESIZE)
    if buffer.Offset ~= old then return true end
  end,
  --------------------------------------------------------------------
  -- clear console buffer
  --------------------------------------------------------------------
  Clear = function()
    editor:ClearAll()
    editor:AddText(MSG.Help.console)
    editor:DocumentEnd()
  end,
  --------------------------------------------------------------------
  -- display information about current file
  --------------------------------------------------------------------
  Info = function()
    local srcPath = buffer.SrcPath or "(untitled)"
    local dataSz = buffer.DataSz
    local edited = buffer.Edited and "changed" or "unchanged"
    local searchInfo = buffer.SearchInfo or "(none)"
    local searchType = buffer.SearchType or "(none)"
    editor:AddText(
      "File path:   "..srcPath.."\n"..
      "File size:   "..dataSz.."\n"..
      "Edit flag:   "..edited.."\n"..
      "Search info: "..searchInfo.."\n"..
      "Search type: "..searchType.."\n"
    )
  end,
  --------------------------------------------------------------------
  -- revert to original file if possible
  --------------------------------------------------------------------
  Revert = function()
    local data, dataSz
    if buffer.SrcPath then                      -- reload from file
      data, dataSz = LoadData(buffer.SrcPath)
      if not data then
        CmdError("Failed to reload file while trying to revert to original")
        return
      end
    else                                        -- get original buffer data
      data = buffer.OrigData
      dataSz = string.len(data)
    end
    if buffer.DataSz ~= dataSz then             -- fail if changed
      CmdError("Length of original file has changed, cannot revert")
      return
    end
    buffer.Data = data                          -- reset
    buffer.ChangeSet = {}
    buffer.Edited = false
  end,
  --------------------------------------------------------------------
  -- move page and caret to a given position
  --------------------------------------------------------------------
  Goto = function(args)
    if type(args) == "table" then               -- from console
      if CheckForArg(args) then return end
      args = args[1]
      args = IsDec(args) or IsHex(args)
      if not args then
        buffer.AutoClose = false
        CmdError("Argument is not a number")
        return
      end
    end
    if args >= buffer.DataSz and args > 0 then  -- fail if out of range
      if buffer.Mode == "console" then
        buffer.AutoClose = false
        CmdError("Target position out of range")
      end
      return
    end
    buffer.Offset = Align(args, PAGESIZE)       -- set position info
    local pos = args - buffer.Offset
    if buffer.Mode == "console" then
      buffer.EditPos = tostring(pos)            -- delayed til UnConsole
    end
  end,
  --------------------------------------------------------------------
  -- convert data into other forms
  --------------------------------------------------------------------
  Number = function(args)
    if CheckForArg(args) then return end
    local ULONG_MAX, LONG_MAX, LONG_MIN =       -- support INT32
      4294967295, 2147483647, -2147483648
    ----------------------------------------------------------------
    local function Reverse(h)                   -- switch endiannes
      local r = "0x"
      h = string.sub(h, 3)
      h = string.rep("0", 8 - string.len(h))..h -- fix to 32 bit
      for i = string.len(h)-1, 1, -2 do r = r..string.sub(h, i, i+1) end
      return r
    end
    ----------------------------------------------------------------
    local arg = args[1]
    local h, d, q1, q2 =
      IsHex(arg), IsDec(arg), IsQuote1(arg), IsQuote2(arg)
    ----------------------------------------------------------------
    if h then                                   -- from hex
      editor:AddText(
        "Decimal: "..h.." (big endian)\n"..
        "Decimal: "..IsHex(Reverse(h)).." (little endian)\n"
      )
    ----------------------------------------------------------------
    elseif d then                               -- from decimal
      if math.floor(d) == d and
         d <= ULONG_MAX and d >= LONG_MIN then
        if d < 0 then d = ULONG_MAX + 1 + d end
        h = string.format("0x%08X", d)
      else
        h = "out of 32-bit range"
        q1 = "out of 32-bit range"
      end
      editor:AddText(
        "Hex: "..h.." (big endian)\n"..
        "Hex: "..Reverse(h).." (little endian)\n"
      )
    ----------------------------------------------------------------
    elseif q1 or q2 then                        -- from string
      local q = q1 or q2
      local h = "0x"
      for i = 1, string.len(q) do
        h = h..string.format("%02X", string.byte(q, i))
      end
      editor:AddText(
        "Hex: "..h.."\n"
      )
    ----------------------------------------------------------------
    else
      CmdError("Argument is not a number or a string")
    end
  end,
  --------------------------------------------------------------------
  -- floating-point number conversion
  --------------------------------------------------------------------
  Float = function(args)
    if CheckForArg(args) then return end
    local arg = args[1]
    local h, d = IsHex(arg), tonumber(arg)
    ----------------------------------------------------------------
    local function CheckFloatHex(s)     -- check and convert hex digits
      local sz, x, n = string.len(s), {}, 0
      if sz ~= 10 and sz ~= 18 then return end
      for i = 3, sz, 2 do
        n = n + 1; x[n] = tonumber(string.sub(s, i, i+1), 16)
      end
      return x, n
    end
    ----------------------------------------------------------------
    local function InFloatRange(x)      -- check if in single range
      local FLT_MIN, FLT_MAX = 1.17549435e-38, 3.40282347e+38
      if x < 0 then x = -x end
      if x == 1/0 or (x >= FLT_MIN and x <= FLT_MAX) then return true end
    end
    ----------------------------------------------------------------
    if h then                                   -- from hex
      arg, h = CheckFloatHex(arg)
      if not arg then
        CmdError("Must be a 4 or 8 byte hex sequence")
        return
      end
      if h == 4 then
        arg = hex2single(arg); h = "Single"
      else
        arg = hex2double(arg); h = "Double"
      end
      if type(arg) ~= "string" then arg = string.format("%g", arg) end
      editor:AddText(h..": "..arg.."\n")
    ----------------------------------------------------------------
    else
      if not d then                             -- check special values
        d = string.lower(arg)
        if d == "inf" or d == "inf+" then d = 1/0
        elseif d == "inf-" then d = -1/0
        else d = nil
        end
      end
      if d then                                 -- from decimal
        if InFloatRange(d) then
          editor:AddText("Single: "..single2hex(d).."\n")
        end
        editor:AddText("Double: "..double2hex(d).."\n")
      else
        CmdError("Argument must be a hex or floating-point number")
      end
    end
  end,
  --------------------------------------------------------------------
  -- load a new file to edit
  --------------------------------------------------------------------
  Load = function(args)
    buffer.AutoClose = false
    if CheckForArg(args) then return end
    local arg = args[1]
    local q1, q2 = IsQuote1(arg), IsQuote2(arg)
    arg = q1 or q2 or arg                       -- quote handling
    if buffer.Edited then
      CmdError("There are unsaved changes, cannot load a new file")
      return
    end
    local data, dataSz = LoadData(arg)          -- try to load the file
    if not data then
      CmdError("Failed to load file '"..arg.."'")
      return
    end
    buffer.SrcPath = arg                        -- initialize buffer
    buffer.Data = data
    buffer.DataSz = dataSz
    buffer.ChangeSet = {}
    buffer.Edited = false
    buffer.Offset = 0
    buffer.EditPos = tostring(0)
    buffer.AutoClose = true
  end,
  --------------------------------------------------------------------
  -- save an edited file
  --------------------------------------------------------------------
  Save = function(args)
    buffer.AutoClose = false
    if CheckForArg(args, 0, 1) then return end
    local arg = args[1]
    if not arg then
      arg = buffer.SrcPath
    else
      local q1, q2 = IsQuote1(arg), IsQuote2(arg)
      arg = q1 or q2 or arg                     -- quote handling
    end
    if not arg then
      CmdError("Buffer is untitled, a file path is required")
      return
    end
    if buffer.DataSz == 0 then
      CmdError("Cannot save an empty buffer")
      return
    end
    if SaveData(arg, buffer.Data) then          -- try to save the file
      buffer.SrcPath = arg                      -- update state, continue
      buffer.ChangeSet = {}
      buffer.Edited = false
    else
      CmdError("Failed to save file '"..arg.."'")
      return
    end
    buffer.AutoClose = true
  end,
  --------------------------------------------------------------------
  -- find literal data or match for data using a regexp
  --------------------------------------------------------------------
  DoSearch = function(args)
    local searchType, searchInfo
    buffer.AutoClose = false
    if CheckForArg(args) then return end
    local arg = args[1]
    local h, d, q1, q2 =
      IsHex(arg), IsDec(arg), IsQuote1(arg), IsQuote2(arg)
    ----------------------------------------------------------------
    if h then                                   -- hex data specified
      h = string.sub(arg, 3)
      if math.mod(string.len(h), 2) == 1 then h = "0"..h end
      local info = ""
      for i = 1, string.len(h), 2 do
        info = info..string.char(tonumber(string.sub(h, i, i+1), 16))
      end
      searchInfo = info
      searchType = "literal"
    ----------------------------------------------------------------
    elseif d then
      CmdError("Please enclose a literal string in quotes")
      return
    ----------------------------------------------------------------
    elseif q1 then                              -- literal specified
      searchInfo = q1
      searchType = "literal"
    ----------------------------------------------------------------
    elseif q2 then                              -- regexp specified
      searchInfo = q2
      searchType = "regexp"
    ----------------------------------------------------------------
    else
      CmdError("Please enclose a literal string in quotes")
      return
    ----------------------------------------------------------------
    end
    if buffer.DataSz == 0 then
      CmdError("Cannot search an empty buffer")
      return
    end
    local x1, x2                                -- perform initial search
    if searchType == "literal" then
      x1, x2 = string.find(buffer.Data, searchInfo, 1, 1)
    else-- searchType == "regexp" then
      x1, x2 = string.find(buffer.Data, searchInfo)
    end
    if not x1 then
      CmdError("No match for "..searchType.." search string '"..searchInfo.."'")
      return
    end
    buffer.SearchEnd = x2                       -- save info for FindNext
    buffer.SearchInfo = searchInfo
    buffer.SearchType = searchType
    x1 = x1 - 1
    buffer.Offset = Align(x1, PAGESIZE)         -- set found position
    local pos = x1 - buffer.Offset
    buffer.EditPos = tostring(pos)              -- delayed til UnConsole
    buffer.AutoClose = true
  end,
  --------------------------------------------------------------------
  --TODO: find and replace init
  -- * involves change of data size, need to adjust a few things...
  --------------------------------------------------------------------
--DoReplace = function(args)
--end,
  --------------------------------------------------------------------
  -- further searching for literal data or regexp match
  --------------------------------------------------------------------
  FindNext = function()
    local beg = buffer.SearchEnd                -- get info
    local searchInfo = buffer.SearchInfo
    local searchType = buffer.SearchType
    if not beg then                             -- no search, silently fails
      editor:CharRight()
      return
    end
    if buffer.DataSz == 0 then
      CmdError("Cannot search an empty buffer")
      return
    end
    local x1, x2                                -- perform next search
    while not x1 do
      if searchType == "literal" then
        x1, x2 = string.find(buffer.Data, searchInfo, beg + 1, 1)
      else-- searchType == "regexp" then
        x1, x2 = string.find(buffer.Data, searchInfo, beg + 1)
      end
      if not x1 then                            -- try to restart search
        if beg ~= 1 then beg = 1                -- retry from beginning
        else CmdError("No match found") return
        end
      else
        break
      end
    end--while
    buffer.SearchEnd = x2                       -- save info for FindNext
    x1 = x1 - 1
    buffer.Offset = Align(x1, PAGESIZE)         -- set found position
    local pos = x1 - buffer.Offset
    MoveToHex(pos)
    editor:CharRight()
  end,
  --------------------------------------------------------------------
  --TODO: find and replace next
  --------------------------------------------------------------------
--Replace = function()
--end,
  --------------------------------------------------------------------
  -- extract strings from buffer
  --------------------------------------------------------------------
  Strings = function()
    if buffer.DataSz == 0 then
      CmdError("Cannot extract strings from an empty buffer")
      return
    elseif not string.find(buffer.Data, "%z") then
      CmdError("Cannot extract strings from a buffer without NULs")
      return
    end
    local beg, nstr = 1, 0
    local x1, x2
    while true do                                       -- search loop
      x1, x2 = string.find(buffer.Data, STRINGSPAT, beg + 1)
      if not x1 then
        break
      end
      beg, x2 = x2, x2 - 1
      local slen, flag = x2 - x1, " "
      if slen >= STRINGSMIN then                        -- find candidate
        local str = string.sub(buffer.Data, x1, x2)
        if slen > STRINGSMAX then                       -- truncate
          str, flag = string.sub(str, 1, STRINGSMAX), "+"
        end
        editor:AddText(string.format("[%08X%s]: %s\n", x1-1, flag, str))
        nstr = nstr + 1
      end
    end--while
    if nstr == 0 then CmdError("No strings found") end
  end,
  --------------------------------------------------------------------
  -- make changes based on keypress in ascii pane
  --------------------------------------------------------------------
  EditAscii = function(x, y, c)
    local pos = buffer.Offset + y * 16 + x
    local v = string.byte(c)
    local result = SetByte(pos, v)              -- make the changes
    if result then MarkAsEdited(pos) end
    return result
  end,
  --------------------------------------------------------------------
  -- make changes based on keypress in hex pane
  --------------------------------------------------------------------
  EditHex = function(x, y, digit, c)
    local pos = buffer.Offset + y * 16 + x
    local v = GetByte(pos)
    c = tonumber(c, 16)
    if digit == 0 then                          -- according to digit pos
      v = c * 16 + math.mod(v, 16)
    else
      v = math.floor(v / 16) * 16 + c
    end
    local result = SetByte(pos, v)              -- make the changes
    if result then MarkAsEdited(pos) end
    return result
  end,
  --------------------------------------------------------------------
}

------------------------------------------------------------------------
-- console command processing
------------------------------------------------------------------------
local function DoConsole()
  local c
  buffer.AutoClose = true
  --------------------------------------------------------------------
  -- process arguments prior to command execution
  --------------------------------------------------------------------
  local function ProcessArgs(s)
    local i, slen, args = 1, string.len(s), {}
    while i <= slen do                  -- iteratively process args
      local c = string.sub(s, i, i)
      if c == "'" or c == '"' then      -- find a quoted argument
        local j = string.find(s, c, i+1, 1)
        if not j then
          buffer.AutoClose = false
          CmdError("Malformed string in command line")
          return {}
        end
        c = string.sub(s, i, j) table.insert(args, c)
        i = j + 1
      else                              -- find an unquoted argument
        local j, k = string.find(s, "%s+", i)
        if not j then
          c = string.sub(s, i) table.insert(args, c)
        elseif j > i then
          c = string.sub(s, i, j-1) table.insert(args, c)
        else
          c = "" i = k + 1
        end
        i = i + string.len(c)
      end
    end--while
    return args
  end
  --------------------------------------------------------------------
  -- process "command line" entered at prompt
  --------------------------------------------------------------------
  local txt = editor:LineFromPosition(editor.CurrentPos) - 1
  txt = editor:GetLine((txt > 0) and txt or 0)
  while string.find(txt, "%s$") do txt = string.sub(txt, 1, -2) end
  local x1, x2 = string.find(txt, "^>%s*")      -- check for prompt
  if not x1 then
    buffer.AutoClose = false
    CmdError("Please enter commands only at prompt line") return
  end
  txt = string.sub(txt, x2 + 1)                 -- extract command
  x1, x2, c = string.find(txt, "^([%S]+)%s*")
  c = c or ""
  if string.find(c, "[^%-]%-$") then            -- autoclose toggle
    c = string.sub(c, 1, -2)
    buffer.AutoClose = not buffer.AutoClose
  end
  c = string.lower(c)
  --------------------------------------------------------------------
  -- process commands
  --------------------------------------------------------------------
  if x1 then
    local args = ProcessArgs(string.sub(txt, x2 + 1))
    ----------------------------------------------------------------
    if c == "exit" or c == "close" then -- exit console screen
      buffer.AutoClose = true
    ----------------------------------------------------------------
    elseif c == "help" then             -- switch to help screen
      buffer.AutoClose = false
      Command.Help(args)
    ----------------------------------------------------------------
    elseif c == "goto" then             -- other commands
      Command.Goto(args)
    elseif c == "revert" then
      Command.Revert()
    elseif c == "load" then
      Command.Load(args)
    elseif c == "save" or c == "saveas" then
      Command.Save(args)
    elseif c == "search" then
      Command.DoSearch(args)
--  elseif c == "replace" then
--    Command.DoReplace(args)
    ----------------------------------------------------------------
    elseif c == "number" then           -- these doesn't close window
      buffer.AutoClose = false
      Command.Number(args)
    elseif c == "float" then
      buffer.AutoClose = false
      Command.Float(args)
    elseif c == "strings" then
      buffer.AutoClose = false
      Command.Strings()
    elseif c == "info" then
      buffer.AutoClose = false
      Command.Info()
    elseif c == "cls" then
      buffer.AutoClose = false
      Command.Clear()
    ----------------------------------------------------------------
    else                        -- unknown command, display info
      editor:AddText("@ Unrecognized command '"..c.."'\n@ Arguments:")
      if table.getn(args) == 0 then
        editor:AddText("(None)\n")
      else
        for i, v in ipairs(args) do
          editor:AddText("\n@ ["..i.."]='"..v.."'")
        end
        editor:AddText("\n")
      end
      buffer.AutoClose = false
    ----------------------------------------------------------------
    end--if c
    if buffer.AutoClose then    -- exits done here else, next prompt
      Command.UnConsole() return
    end
  end--if x1
  editor:AddText(CONSOLEPROMPT)
end

------------------------------------------------------------------------
-- main processing function
-- * line positions start from 0, column positions start from 1
------------------------------------------------------------------------
local function HexEdit(c, clicked)
  local pos = editor.CurrentPos
  local ln = editor:LineFromPosition(pos)
  local col = editor.Column[pos]
  --------------------------------------------------------------------
  -- function to check window bounds, shifted for newlines (why?)
  --------------------------------------------------------------------
  local function InWindow(WINDOW, x, y, c)
    if y >= WINDOW.y1 and y <= WINDOW.y2 then
      if (x >= WINDOW.x1 and x <= WINDOW.x2 and c ~= "\n") or
         (x >= WINDOW.x1-1 and x <= WINDOW.x2-1 and c == "\n") then
        return true end
    end
  end
  --------------------------------------------------------------------
  -- function to move to next element, or next page if required
  --------------------------------------------------------------------
  function MoveNext(pos)
    pos = pos or PAGESIZE
    if pos == PAGESIZE then
      if Command.Next(PAGESIZE) then
        MoveToHex(0); editor:CharRight()
      end
    else
      MoveToHex(pos)
    end
  end
  --------------------------------------------------------------------
  -- function to jump to next page for [Enter] movement
  --------------------------------------------------------------------
  function NextPage()
    if Command.Next(PAGESIZE) then
      for i = 1, 16 do editor:LineUp() end
    else
      editor:LineUp()
    end
  end
  --------------------------------------------------------------------
  -- handle non-edit modes
  --------------------------------------------------------------------
  local mode = buffer.Mode
  if mode == string.upper(mode) then    -- switch from help mode
    if (KeyMap[c] or c) == "Help" then
      Command.UnHelp()
    end
    return
  elseif mode == "console" then         -- console mode
    if c == "\n" then DoConsole() end
    return
  elseif mode ~= "edit" then
    Error("Unknown mode encountered, please check the sources")
  end
  --------------------------------------------------------------------
  -- edit mode; filter keys, separate operations according to windows
  --------------------------------------------------------------------
  local op
  if InWindow(WIN.POS, col, ln, c) then
    if string.find(c, "%x") or c == "\n" then op = "pos" end
  end
  if InWindow(WIN.HEX, col, ln, c) then
    if string.find(c, "%x") or c == "\n" or c == " " then op = "hex" end
  end
  if InWindow(WIN.ASC, col, ln, c) then
    op = "asc"
  end
  --------------------------------------------------------------------
  -- alternate button activation, keypress translation
  --------------------------------------------------------------------
  local cmd = ""
  if not op then
    if c == " " and ln == MSG.ButtonLn then     -- space on button
      for i,b in ipairs(Buttons) do
        if col >= b[1] and col <= b[2] then cmd = b[3] end
      end
    else                                        -- keypress check
      cmd = KeyMap[c] or c
    end
  end
  if string.len(cmd) > 1 then op = "cmd" end
  --------------------------------------------------------------------
  -- edit window operations
  --------------------------------------------------------------------
  if op == "pos" then                   -- offset window operations
    if c == "\n" then
      -- newline moves caret down
      if ln - WIN.POS.y1 == 15 then NextPage() end
    else
      local p = string.format("%08X", buffer.Offset)
      col = col - WIN.POS.x1 + 1
      p = string.sub(p, 1, col-1)..c..string.sub(p, col+1)
      Command.Goto(tonumber(p, 16))
    end
  --------------------------------------------------------------------
  elseif op == "hex" then               -- hex window operations
    col = col - WIN.HEX.x1 - 1
    ln = ln - WIN.HEX.y1
    local digit = math.mod(col, 3)
    if c == "\n" then
      -- newline moves caret down, does not change data
      if ln == 15 then NextPage() end
    elseif c == " " then                -- space movement
      if col == -1 then
        editor:CharRight()
      else
        for i = 1, 3-digit do editor:CharRight() end
      end
      col = (col - digit) / 3
      if col == 15 then
        MoveNext(ln * 16 + col + 1)
      end
    else                                -- edit a hex digit
      if digit == 2 then
        -- space in between hex digits, nothing happens
      elseif col >= 0 then
        col = (col - digit) / 3
        if Command.EditHex(col, ln, digit, c) then
          editor:CharRight()            -- move after edit
          if digit == 1 then
            editor:CharRight()
            if col == 15 then MoveNext(ln * 16 + col + 1) end
          end
        end
      end--if digit
    end--if c
  --------------------------------------------------------------------
  elseif op == "asc" then               -- ascii window operations
    if c == "\n" then
      -- newline moves caret down, does not change data
      if ln - WIN.HEX.y1 == 15 then NextPage() end
    else
      col = col - WIN.ASC.x1
      ln = ln - WIN.HEX.y1
      if Command.EditAscii(col, ln, c) then
        pos = ln * 16 + col + 1
        if pos == PAGESIZE then
          if Command.Next(PAGESIZE) then
            MoveToAscii(0); editor:CharRight()
          end
        else
          MoveToAscii(pos)  -- move after edit
        end
      end
    end
  --------------------------------------------------------------------
  -- command operations
  --------------------------------------------------------------------
  elseif op == "cmd" then
    if cmd == "Help" then                       -- switch to help mode
      if not clicked then editor:DeleteBack() end
      Command.Help("edit")
      return
    elseif cmd == "Console" then                -- switch to console mode
      if not clicked then editor:DeleteBack() end
      Command.Console()
      return
    elseif cmd == "Refresh" then                -- refresh, does nothing here
    elseif cmd == "Revert" then                 -- reload original
      Command.Revert()
    elseif cmd == "NextPg" then                 -- next page
      Command.Next(PAGESIZE)
    elseif cmd == "PrevPg" then                 -- previous page
      Command.Prev(PAGESIZE)
    elseif cmd == "Next1K" then                 -- next 1K
      Command.Next(PAGE1K)
    elseif cmd == "Prev1K" then                 -- previous 1K
      Command.Prev(PAGE1K)
    elseif cmd == "FirstPg" then                -- first page
      Command.First()
    elseif cmd == "LastPg" then                 -- last page
      Command.Last()
    elseif cmd == "FindNext" then               -- find next match
      editor:DeleteBack()
      Command.FindNext()
--  elseif cmd == "Replace" then                -- find & replace
--    Command.Replace()
    else
      Error("Failed attempt to run unknown command '"..c.."'")
    end
  --------------------------------------------------------------------
  end
  --------------------------------------------------------------------
  -- pos readjustment; needed if caret moved up or down after this...
  --------------------------------------------------------------------
  if c == "\n" then
    if op then editor:LineDown() end
  else
    editor:CharLeft()
  end
end

------------------------------------------------------------------------
-- display and styling functions (performs complete refreshes)
------------------------------------------------------------------------

-- colourise, called for the edit window only
local function Colourise()
  local STYLEBITS = 31
  local LINES = PAGESIZE / 16
  local page = math.floor(buffer.Offset / PAGESIZE)     -- for lookup
  page = buffer.ChangeSet[page]
  local CharColours = buffer.CharColours
  --------------------------------------------------------------------
  local function IsEdited(i)                    -- get change status
    if not page then return false end           -- (uses string index)
    return string.byte(page, i) == 1
  end
  --------------------------------------------------------------------
  local function LineSpan(ln)                   -- get extent of line
    local x1 = editor:PositionFromLine(ln)
    local x2 = editor:PositionFromLine(ln+1)
    return x1, x2-1, x2-x1
  end
  --------------------------------------------------------------------
  local function SetLine(i, style)              -- set line to style
    local _, _, sz = LineSpan(i)
    editor:SetStyling(sz, style)
  end
  --------------------------------------------------------------------
  local x1, x2, sz
  editor:StartStyling(0, STYLEBITS)
  SetLine(0, 8)                 -- title
  --------------------------------------------------------------------
  SetLine(1, 16)                -- button bar top
  x1, x2, sz = LineSpan(2)
  local s = MSG.Butln           -- button text
  for i = 1, sz do
    if string.byte(s, i) == 45 then editor:SetStyling(1, 17)
    else editor:SetStyling(1, 16)
    end
  end
  SetLine(3, 16)                -- button bar bottom
  --------------------------------------------------------------------
  SetLine(4, 32)                -- edit window line (top)
  SetLine(5, 18)                -- edit window header
  SetLine(6, 32)                -- edit window line
  --------------------------------------------------------------------
  for i = 0, LINES-1 do                 -- edit window data line
    x1, x2, sz = LineSpan(i + 7)
    editor:SetStyling(1, 32)                    -- border (left)
    editor:SetStyling(8, 19)                    -- position
    editor:SetStyling(2, 32)                    -- border
    local lineBeg = i * 16 + 1
    for p = lineBeg, lineBeg + 15 do            -- hex data
      local c = string.byte(buffer.Data, buffer.Offset + p)
      if not c then
        c = 6
      else
        c = string.byte(CharColours, c+1)
      end
      if IsEdited(p) then c = c + 8 end
      editor:SetStyling(2, c)
      editor:SetStyling(1, 32)
    end
    editor:SetStyling(1, 32)                    -- border
    for p = lineBeg, lineBeg + 15 do            -- ascii data
      local c = 7
      if IsEdited(p) then c = c + 8 end
      editor:SetStyling(1, c)
    end
    editor:SetStyling(sz - 76, 32)      -- border (right)
  end
  --------------------------------------------------------------------
  local l = LINES + 7
  SetLine(l, 32)                -- edit window line (bottom)
  SetLine(l+1, 20)              -- information box (top)
  SetLine(l+2, 21)              -- save file info line
  for i = l+3, l+6 do           -- information box
    SetLine(i, 20)
  end
end

-- refresh the entire window, based on window mode
local function Refresh()
  local table = table
  local LINES = PAGESIZE / 16   -- windows are hardcoded elsewhere...
  local savedpos = editor.CurrentPos
  local mode = buffer.Mode
  --------------------------------------------------------------------
  -- display edit mode (normal)
  --------------------------------------------------------------------
  if mode == "edit" then
    editor:ClearAll()
    ----------------------------------------------------------------
    -- filepath and edit state display
    ----------------------------------------------------------------
    local srcName = buffer.SrcPath or "(untitled)"
    local edited = buffer.Edited and "(changed)" or "(unchanged)"
    local n = MSG.FootWinSz - 5 - string.len(edited)
    local fn = string.len(srcName)
    if fn > n then srcName = "..."..string.sub(srcName, fn-(n-3)+1)
    elseif n > fn then srcName = srcName..string.rep(" ", n-fn)
    end
    ----------------------------------------------------------------
    -- build edit window
    ----------------------------------------------------------------
    local i, data = buffer.Offset + 1, buffer.Data
    local ln = {}
    for y = 0, LINES-1 do                       -- each line
      table.insert(ln, "|"..string.format("%08X", i - 1).. "| ")
      local ascii = "|"
      for x = 0, 15 do                          -- each byte
        local c = string.byte(data, i) or 0
        table.insert(ln, string.format("%02X ", c)) -- hex byte
        if c < 32 then c = NONPRINTING end
        ascii = ascii..string.char(c)
        i = i + 1
      end
      table.insert(ln, ascii)                   -- ascii data
      table.insert(ln, "|\n")
    end
    ln = table.concat(ln)
    ----------------------------------------------------------------
    -- main call to display edit window
    ----------------------------------------------------------------
    editor:AddText(
      MSG.Header..
      MSG.Butln..MSG.Buttons..MSG.Butln..
      MSG.EditWinLn..MSG.EditLegend..MSG.EditWinLn..
      ln..
      MSG.EditWinLn..
      MSG.FootWinLn..
      "| "..srcName.." "..edited.." |\n"..
      MSG.FootWinLn..MSG.Footer..MSG.FootWinLn
    )
    editor:GotoPos(savedpos)
    Colourise()
  --------------------------------------------------------------------
  -- display console mode
  --------------------------------------------------------------------
  elseif mode == "console" then
    -- console mode does not refresh the screen
  --------------------------------------------------------------------
  -- display help mode (identified as "EDIT" or "CONSOLE")
  --------------------------------------------------------------------
  else
    editor:ClearAll()
    editor:AddText(MSG.Help.edit)
    editor:DocumentEnd()
    editor:Colourise(0,-1)
  end
end

------------------------------------------------------------------------
-- handle incoming events
------------------------------------------------------------------------

local function HandleClick()
  if not buffer[SIG] then return end    -- verify buffer signature
  local pos = editor.CurrentPos
  local ln = editor:LineFromPosition(pos)
  local col = editor.Column[pos]
  if not ln == MSG.ButtonLn then        -- check for button click
    return true end
  for i,b in ipairs(Buttons) do
    if col >= b[1] and col <= b[2] then HexEdit(b[3], true) end
  end
  Refresh()
  return true
end

local function HandleChar(c)
  if not buffer[SIG] then return end    -- verify buffer signature
  HexEdit(c)
  Refresh()
  return true
end

local function HandleSwitchFile()
  if not buffer[SIG] then return end    -- verify buffer signature
  if buffer.Mode == "edit" then
    SetColours(SCLEX_CONTAINER, ColourScheme)
    Colourise()
  else
    SetColours(SCLEX_DIFF, ColourSchemeDiff)
    editor:Colourise(0,-1)
  end
  return true
end

------------------------------------------------------------------------
-- hex editor initialization
------------------------------------------------------------------------

-- simply call HexEditor() for normal behaviour (open current viewed file)
local function HexEditorBase(NoCurrent)
  --------------------------------------------------------------------
  -- get path of file currently viewed, for later loading
  -- * many things can be set only after the scite.Open("") call
  --------------------------------------------------------------------
  local srcExt = props["FileNameExt"] or ""
  local srcPath, srcPos, startPos, srcData
  if not NoCurrent then                 -- want to open existing file
    if srcExt ~= "" then                -- there is an open file
      srcPath = props["FilePath"]
      srcPos = editor.CurrentPos
    else
      srcData = editor:GetText()        -- buffer may be non-empty
      srcPos = editor.CurrentPos
    end
  end
  --------------------------------------------------------------------
  -- initialize the user interface, initialize state
  --------------------------------------------------------------------
  scite_OnDoubleClick(HandleClick)      -- set up handlers
  scite_OnChar(HandleChar)
  scite_OnSwitchFile(HandleSwitchFile)
  scite.Open("")                        -- create a new buffer
  buffer[SIG] = true;
  buffer.Mode = "edit"
  --------------------------------------------------------------------
  if srcPath then                       -- load an existing file
    local data, dataSz = LoadData(srcPath)
    if data then
      buffer.SrcPath = srcPath
      buffer.Data = data
      buffer.DataSz = dataSz
      buffer.Offset = Align(srcPos, PAGESIZE)
      startPos = srcPos - buffer.Offset
    end
  end
  --------------------------------------------------------------------
  if not buffer.Data then               -- no current file
    buffer.SrcPath = nil
    buffer.Data = srcData or ""
    buffer.DataSz = string.len(buffer.Data)
    srcPos = srcPos or 0
    buffer.Offset = Align(srcPos, PAGESIZE)
    startPos = srcPos - buffer.Offset
    buffer.OrigData = buffer.Data
  end
  --------------------------------------------------------------------
  buffer.Edited = false                 -- common initialization
  buffer.ChangeSet = {}
  WindowSetup()
  SetColours(SCLEX_CONTAINER, ColourScheme)
  Refresh()
  MoveToHex(startPos)
end

-- call this if you don't want the hex editor to open the current file
function HexEditorNew() HexEditorBase(true) end

-- somehow SciTE needs this, otherwise it can't see current properties
function HexEditor() HexEditorBase() end

-- end of script
