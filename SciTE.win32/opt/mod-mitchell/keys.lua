--[[
  Mitchell's keys.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Documentation can be found in scripts/doc/keys_doc.txt
]]--

---
-- Manages key commands in SciTE.
-- Key commands are defined in a separate key_commands.lua file that is located
-- in the same directory or package.path.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows)
--   SCOPES_ENABLED: Flag indicating whether scopes/styles can be used for key
--     commands.
--   CTRL: The string representing the Control key.
--   SHIFT: The string representing the Shift key.
--   ALT: The string representing the Alt key.
--   ADD: The string representing used to join together a sequence of Control,
--     Shift, or Alt modifier keys.
--   KEYCHAIN_PROP: The SciTE property that will be updated each time the
--     keychain is modified.
module('modules.scite.keys', package.seeall)

-- Usage:
-- Syntax:
--   Key commands are defined in a user-defined table 'keys'. Scopes and Lexers
--   (discussed below) are numeric indices of the keys table and are tables
--   themselves. Each string index in each of these tables is the key command.
--   The table containing the command to execute and an optional parameter is
--   equated to this key command. You can have global key commands of course.
--
--   For example:
--   local m_editing = modules.scite.editing
--   local m_snippets = modules.scite.snippets
--   keys = {
--     ['ctrl+f']   = { editor.CharRight, editor },
--     ['ctrl+b']   = { editor.CharLeft,  editor },
--     [SCLEX_RUBY] = {
--       ['ctrl+e']   = { m_editing.ruby_exec },
--       [SCE_RB_DEFAULT] = {
--         ['ctrl+f'] = { m_snippets.insert, 'function ${1:name}' }
--       }
--     }
--   }
--
--   The top-level key commands are global, the SCLEX_RUBY command is global to
--   a buffer with Ruby syntax highlighting enabled, and the SCE_RB_DEFAULT
--   command is executed in that buffer only when currently in the default
--   scope.
--
--   Scopes and Lexers:
--     SCLEX_RUBY and SCE_RB_DEFAULT are both constants having values defined in
--     Scintilla.iface (22 and 0 respectively).
--
--     Scope-insensitive key commands should be placed in the lexer table, and
--     lexer-insensitive key commands should be placed in the keys table.
--
--   By default scopes are enabled. To disable them, set the SCOPES_ENABLED
--   variable to false.
--
--   Order of execution precedence: Scope, Lexer, Global.
--     Key commands in the current scope have the first priority, commands in
--     the current lexer have the second, and global commands have the least
--     priority.
--
--   Declaring key commands: ['key_seq'] = { command [, arg] }
--     ( e.g. ['ctrl+i'] = { modules.scite.snippets.insert } )
--     key_seq is the key sequence string compiled from the CTRL, SHIFT, ALT,
--     and ADD options (discussed below), command is the Lua function or SciTE
--     menu command number (defined in SciTE.h), and arg is an optional
--     argument. If I wanted to redefine the 'Open' menu command to be 'ctrl+r',
--     then I would do something like ['ctrl+r'] = { 102 } -- open.
--     Editor pane commands are kind of tricky at first. Their argument is the
--     editor pane itself. You can see this in the original example above.
--     The key character is ALWAYS lower case. There will be no such command as
--     ['ctrl+I'].
--     The string representation of characters is used, so ['ctrl+/'] is a valid
--     key sequence. (See limitations of this below.)
--     The order of CTRL, SHIFT, and ALT is important. (C, CS, CA, CSA, etc.)
--
--   Chaining key commands:
--     Key commands can be chained like in Emacs. All you have to do create
--     nested tables as values of key commands.
--
--     For Example:
--     keys = {
--       ['ctrl+x'] = {
--         ['ctrl+s'] = { 106 } -- save
--         ['ctrl+c'] = { 140 } -- quit
--       }
--     }
--
--     Remember to define a clear_sequence key sequence in the keys table
--     (Escape by default) in order to stop the current chain.
--     If a show_completions key sequence is defined, a list of completions for
--     the current chain will be displayed in the output pane.
--     The current key sequence is contained in the SciTE variable KeyChain.
--     (Appropriate for statusbar display)
--
--   Additional syntax options:
--     The text for CTRL, SHIFT, ALT, and ADD can be changed. ADD is the text
--     inserted between modifiers ('+' in the example above). They can be as
--     simple as c, s, a, [nothing] respectively. ( ['csao'] would be
--     ctrl+shift+alt+o )
--
-- Extensibility:
--   You don't have to define all of your key commands in one place. I have
--   Ruby-specific key commands in my ruby.lua file for example. All you need to
--   do is add to the keys table. ( e.g. keys[SCLEX_RUBY] = { ... } )
--   Note: additions to the keys table should be at the end of your *.lua file.
--   (See the reason behind this below.)
--
-- Limitations:
--   Certain keys that have values higher than 255 can not be used, except for
--     the keys that are located in the KEYSYMS table. When a key value higher
--     than 255 is encountered, its string value is looked up in KEYSYMS and
--     used in the sequence string.
--   In order for key commands to execute Lua functions properly, the Lua
--     functions must be defined BEFORE the key command references to it. This
--     is why the keys.lua module should be loaded LAST, and key commands added
--     at the bottom of *.lua scripts, after all global functions are defined.
--   The clear_sequence and show_completions key sequences cannot be chained.
--
-- Notes:
--   Redefining any menu Alt+key sequences will override them. So for example if
--     'alt+f' is defined, using Alt+F to access SciTE's File menu will no
--     longer work.
--   Setting ALTERNATIVE_KEYS to true enables my nano-emacs hybrid key layout.

-- options
local PLATFORM = _G.PLATFORM or 'linux'
local SCOPES_ENABLED = true
local CTRL  = 'c' -- or alternately 'ctrl'
local SHIFT = 's' -- or alternately 'shift'
local ALT   = 'a' -- or alternately 'alt'
local ADD   = ''  -- or alternately '+'
local KEYCHAIN_PROP = 'KeyChain'
-- end options

---
-- [Local table] Lookup table for key values higher than 255.
-- If a key value given to OnKey is higher than 255, this table is used to
-- return a string representation of the key if it exists.
-- @class table
-- @name KEYSYMS
local KEYSYMS

---
-- [Local table] (Windows only) Lookup table for characters when the Shift key
-- is pressed.
-- Windows uses the same keycodes even if shift is pressed. So if it is, use
-- the keycode and table to lookup the actual character printed.
local SHIFTED

if PLATFORM == 'linux' then
  KEYSYMS = {          -- from <gdk/gdkkeysyms.h>
    [65288] = '\b',    -- backspace
    [65289] = '\t',    -- tab
    [65293] = '\n',    -- newline
    [65307] = 'esc',   -- escape
    [65535] = 'del',   -- delete
    [65360] = 'home',  -- home
    [65361] = 'left',  -- left
    [65362] = 'up',    -- up
    [65363] = 'right', -- right
    [65364] = 'down',  -- down
    [65365] = 'pup',   -- page up
    [65366] = 'pdown', -- page down
    [65367] = 'end',   -- end
    [65379] = 'ins',   -- insert
    [65470] = 'f1',    -- F1
    [65471] = 'f2',    -- F2
    [65472] = 'f3',    -- F3
    [65473] = 'f4',    -- F4
    [65474] = 'f5',    -- F5
    [65475] = 'f6',    -- F6
    [65476] = 'f7',    -- F7
    [65477] = 'f8',    -- F8
    [65478] = 'f9',    -- F9
    [65479] = 'f10',   -- F10
    [65480] = 'f11',   -- F11
    [65481] = 'f12',   -- F12
  }
elseif PLATFORM == 'windows' then
  KEYSYMS = {
    [8]   = '\b',    -- backspace
    [9]   = '\t',    -- tab
    [13]  = '\n',    -- newline
    [27]  = 'esc',   -- escape
    [32]  = ' ',     -- spacebar
    [33]  = 'pup',   -- page up
    [34]  = 'pdown', -- page down
    [35]  = 'end',   -- end
    [36]  = 'home',  -- home
    [37]  = 'left',  -- left
    [38]  = 'up',    -- up
    [39]  = 'right', -- right
    [40]  = 'down',  -- down
    [45]  = 'ins',   -- insert
    [46]  = 'del',   -- delete
    [91]  = 'win',   -- windows key
    [92]  = 'win',   -- windows key
    [93]  = 'menu',  -- menu key
    [112] = 'f1',    -- F1
    [113] = 'f2',    -- F2
    [114] = 'f3',    -- F3
    [115] = 'f4',    -- F4
    [116] = 'f5',    -- F5
    [117] = 'f6',    -- F6
    [118] = 'f7',    -- F7
    [119] = 'f8',    -- F8
    [120] = 'f9',    -- F9
    [121] = 'f10',   -- F10
    [122] = 'f11',   -- F11
    [123] = 'f12',   -- F12
    [186] = ';',     -- semicolon
    [187] = '=',     -- equals
    [188] = ',',     -- comma
    [189] = '-',     -- hypen
    [190] = '.',     -- period
    [191] = '/',     -- forward slash
    [192] = '`',     -- accent
    [219] = '[',     -- left bracket
    [220] = '\\',    -- back slash
    [221] = ']',     -- right bracket
    [222] = '\'',    -- single quote
  }
  SHIFTED = {
    [49]  = '!', [50]  = '@', [51]  = '#', [52]  = '$', [53]  = '%',
    [54]  = '^', [55]  = '&', [56]  = '*', [57]  = '(', [48]  = ')',
    [186] = ':', [187] = '+', [188] = '<', [189] = '_', [190] = '>',
    [191] = '?', [192] = '~', [219] = '{', [220] = '|', [221] = '}',
    [222] = '"',
  }
end

-- if LINUX ... is quicker than if PLATFORM == 'linux' ...
local LINUX = PLATFORM == 'linux' and true or false

--- [Local table] The current key sequence.
-- @class table
-- @name keychain
local keychain = {}

-- local functions
local try_get_cmd1, try_get_cmd2, try_get_cmd3, try_get_cmd

---
-- Clears the current key sequence.
function clear_key_sequence()
  keychain = {}
  props[KEYCHAIN_PROP] = ''
  scite.UpdateStatusBar()
end

---
-- Determines the possible completions for the current key sequence and prints
-- them out. (Only prints key combinations, not command names.)
function show_completions()
  if #keychain == 0 then return end
  active_table = _G.keys
  if keychain.lexer then active_table = active_table[keychain.lexer] end
  if keychain.scope then active_table = active_table[keychain.scope] end
  for _,key_seq in ipairs(keychain) do active_table = active_table[key_seq] end
  local completion_str = ''
  for key_seq in pairs(active_table) do
    completion_str = completion_str..key_seq..'\t'
  end
  print("Completions for '"..props[KEYCHAIN_PROP].."':")
  print(completion_str)
  print("'".._G.keys.clear_sequence.."' to cancel")
end

---
-- SciTE OnKey Lua extension function.
-- It is called every time a key is pressed and determines which commands to
-- execute or which new key in a chain to enter based on the current key
-- sequence, lexer, and scope.
-- @return OnKey returns what the commands it executes return. If nothing is
--   returned, OnKey returns true by default. A true return value will tell
--   SciTE not to handle the key afterwords.
function _G.OnKey(code, shift, control, alt)
  local key_seq = ''
  if control then key_seq = key_seq..CTRL..ADD end
  if shift   then key_seq = key_seq..SHIFT..ADD end
  if alt     then key_seq = key_seq..ALT..ADD end
  --print(code, string.char(code))
  if LINUX then
    if code < 256 then
      key_seq = key_seq..string.char(code):lower()
    else
      if not KEYSYMS[code] then return end
      key_seq = key_seq..KEYSYMS[code]
    end
  else
    if shift and SHIFTED[code] then
      key_seq = key_seq..SHIFTED[code]
    elseif KEYSYMS[code] then
      key_seq = key_seq..KEYSYMS[code]
    elseif code > 47 then -- printable chars start at 48 (0)
      key_seq = key_seq..string.char(code):lower()
    else
      return
    end
  end

  if key_seq == _G.keys.clear_sequence then
    if #keychain > 0 then clear_key_sequence() return true end
  elseif key_seq == _G.keys.show_completions then
    if #keychain > 0 then show_completions() return true end
  end

  local lexer = editor.Lexer
  local scope = editor.StyleAt[editor.CurrentPos]
  local ret, func, arg
  -- print(key_seq, 'Lexer: '..lexer, 'Scope: '..scope)

  keychain[#keychain + 1] = key_seq
  if SCOPES_ENABLED then
    ret, func, arg = pcall(try_get_cmd1, key_seq, lexer, scope)
    if func == -1 then keychain.lexer, keychain.scope = lexer, scope end
  end
  if not ret and func ~= -1 then
    ret, func, arg = pcall(try_get_cmd2, key_seq, lexer)
    if func == -1 then keychain.lexer = lexer end
  end
  if not ret and func ~= -1 then
    ret, func, arg = pcall(try_get_cmd3, key_seq)
  end

  if ret then
    clear_key_sequence()
    if type(func) == 'function' then
      local ret, retval = pcall(func, arg)
      if ret then
        if type(retval) == 'boolean' then return retval end
      else print(retval) end -- error
    elseif type(func) == 'number' then
      scite.MenuCommand(func)
    end
    return true
  else
    -- Clear key sequence because it's not part of a chain.
    -- (try_get_cmd throws error number -1.)
    if func ~= -1 then
      local size = #keychain - 1
      clear_key_sequence()
      if size > 0 then -- previously in a chain
        props[KEYCHAIN_PROP] = 'Invalid Sequence'
        scite.UpdateStatusBar()
        return true
      end
    else return true end
  end
end

-- Note the following functions are called inside pcall so error handling or
-- checking if keys exist etc. is not necessary.

---
-- [Local function] Tries to get a key command based on the lexer and current
-- scope.
try_get_cmd1 = function(key_seq, lexer, scope)
  return try_get_cmd( _G.keys[lexer][scope], key_seq )
end

---
-- [Local function] Tries to get a key command based on the lexer.
try_get_cmd2 = function(key_seq, lexer)
  return try_get_cmd( _G.keys[lexer], key_seq )
end

---
-- [Local function] Tries to get a global key command.
try_get_cmd3 = function(key_seq)
  return try_get_cmd(_G.keys, key_seq)
end

---
-- [Local function] Helper function to get commands with the current keychain.
-- If the current item in the keychain is part of a chain, throw an error value
-- of -1. This way, pcall will return false and -1, where the -1 can easily and
-- efficiently be checked rather than using a string error message.
try_get_cmd = function(active_table)
  local str_seq = ''
  for _, key_seq in ipairs(keychain) do
    str_seq = str_seq..key_seq..' '
    active_table = active_table[key_seq]
  end
  if not active_table[1] then
    props['KeyChain'] = str_seq
    scite.UpdateStatusBar()
    error(-1, 0)
  end
  return active_table[1], active_table[2]
end

--- Global container that holds all key commands.
-- @class table
-- @name keys
_G.keys = {}

require 'key_commands'
