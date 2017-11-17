-----------------------------------------------------------------------
-- Tic Tac Toe for SciTE Version 2.2
-- Kein-Hong Man <khman@users.sf.net> 20060905
-- This program is hereby placed into PUBLIC DOMAIN
-----------------------------------------------------------------------
-- This script can be installed to a shortcut using properties:
--     command.name.8.*=Tic Tac Toe
--     command.subsystem.8.*=3
--     command.8.*=TicTacToe
--     command.save.before.8.*=2
-- If you use extman, you can do it in Lua like this:
--     scite_Command('Tic Tac Toe|TicTacToe|Ctrl+8')
-----------------------------------------------------------------------
-- * This is a demonstration of a (hopefully) well-behaved Lua-based
--   "application" in SciTE that hooks to handlers, is compatible
--   with extman, and uses mouse doubleclicks as the user interface.
-- * TicTacToe is the main function. It opens a new buffer and the
--   game is played by double-clicking on boxed areas, or by pressing
--   the number keys 1 through 9.
-- * Note that the computer player and the player human are fixed
--   at 'O' and 'X', respectively.
-- * If you play using digit keys, do not change buffer from read-only.
-----------------------------------------------------------------------

------------------------------------------------------------------------
-- constants and primitives
------------------------------------------------------------------------
local string = string
local O, X = 1, 10
local STR = {                           -- various strings
  Sig = "SciTE_TicTacToe2",
  Prompt = ">SciTE_TicTacToe2: ",
  Horiz = "+---+---+---+",
  HorizRegex = "^%+%-%-%-%+%-%-%-%+%-%-%-%+",
  TrioRegex = "^|%s*(%w*)%s*|%s*(%w*)%s*|%s*(%w*)%s*|",
  BoardPat = "12121",
  ToolBar = [[
+----------+----------+
| New Game | Autoplay |
+----------+----------+
]],
}
local MSG = {                           -- game messages
  Title = "SciTE Tic Tac Toe",
  Conflict = "There is an OnDoubleClick conflict, please use extman",
  BadBoard = "Board not recognized, computer cannot continue",
  BadPieces = "Something strange on the board, cannot continue",
  IllegalMove = "Illegal move",
  Borked = "Evaluator borked",
  Key1 = "SciTE: O",
  Key2 = "Human: X",
  Start1 = "Human starts",
  Start2 = "Computer starts",
  AlreadyEnd = "Game has already ended",
  NoMoves = "No more moves to make, draw",
  HumanWin = "Human wins this round",
  ComputerWin = "Computer wins this round",
  Help = [[
For best results, please use a monospace font (press Ctrl+F11 for
monospace font mode.) Double-click boxes to play, or press keys
1 through 9 to make a move. Key positions correspond to the usual
keypad arrangement. For a new game, you can press the N key or
double-click the "NewGame" box. To autoplay, you can press [Space]
or double-click the "Autoplay" box.
]]
}
local BUT = {                           -- fixed button set
  [5] = {{2,4,"7"},{6,8,"8"},{10,12,"9"},},
  [7] = {{2,4,"4"},{6,8,"5"},{10,12,"6"},},
  [9] = {{2,4,"1"},{6,8,"2"},{10,12,"3"},},
  [13] = {{2,11,"NewGame"},{13,22,"Autoplay"},},
}
local function Error(msg) _ALERT(STR.Prompt..msg) end       -- error msg

------------------------------------------------------------------------
-- simple check for extman, partially emulate if okay to do so
------------------------------------------------------------------------
if (OnClick or OnDoubleClick or OnChar) and not scite_Command then
  Error(MSG.Conflict)
else
  -- simple way to add a handler only, can't remove like extman does
  if not scite_OnClick then
    local _OnCK
    scite_OnClick = function(f) _OnCK = f end
    OnClick = function(c) if _OnCK then return _OnCK(c) end end
  end
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
end

------------------------------------------------------------------------
-- tic tac toe functions (implicitly uses O as computer, X as human)
------------------------------------------------------------------------

local function CheckForWin(t, player)   -- see who wins
  local wins = player * 3
  if t[1]+t[5]+t[9] == wins or
     t[3]+t[5]+t[7] == wins then return true end
  for i = 1,3 do
    local j = i * 3
    if t[i]+t[i+3]+t[i+6] == wins or
       t[j-2]+t[j-1]+t[j] == wins then return true end
  end
  return false
end

local function AnyWin(t)                -- see if somebody won
  return CheckForWin(t, X) or CheckForWin(t, O)
end

local function MoveCount(t)             -- counts the number of moves
  local n = 0
  for i = 1, 9 do if t[i] == O or t[i] == X then n = n + 1 end end
  return n
end

-- not-bad movement evaluator (minimax can be easily made perfect)
-- (1) picks the obvious
-- (2) blocks the obvious
-- (3) otherwise pick randomly
local function MoveSimple(t, player)
  local mv, opponent
  if player == X then opponent = O else opponent = X end
  for i = 1, 9 do -- (1)
    if t[i] == 0 then
      t[i] = player
      if CheckForWin(t, player) then t[i] = player return end
      t[i] = 0
    end
  end
  for i = 1, 9 do -- (2)
    if t[i] == 0 then
      t[i] = opponent
      if CheckForWin(t, opponent) then t[i] = player return end
      t[i] = 0
    end
  end
  if MoveCount(t) == 9 then Error(MSG.Borked) return end
  repeat mv = math.random(1, 9) until t[mv] == 0 -- (3)
  t[mv] = player
end
local Evaluate = MoveSimple             -- select evaluator

local function ComputerStart(t)         -- computer may start
  if math.random(1, 10) > 5 then
    t[math.random(1, 9)] = O
    return MSG.Start2
  end
  return MSG.Start1
end

------------------------------------------------------------------------
-- redraws the screen (complete redraw for simplicity)
------------------------------------------------------------------------
local function DrawBoard(t)
  if not t then t = {} end
  local p = function(i)
    if not t[i] then return "   "
    elseif t[i] == O then return " O "
    elseif t[i] == X then return " X "
    else return "   "
    end
  end
  editor:AddText(
    STR.Horiz.."\n"..
    "|"..p(7).."|"..p(8).."|"..p(9).."| "..MSG.Key1.."\n"..
    STR.Horiz.." "..MSG.Key2.."\n"..
    "|"..p(4).."|"..p(5).."|"..p(6).."|\n"..
    STR.Horiz.."\n"..
    "|"..p(1).."|"..p(2).."|"..p(3).."|\n"..
    STR.Horiz.."\n"
  )
end

local function Refresh(t, msg)
  local function Underline(s) return string.rep("-", string.len(s)) end
  msg = msg or ""
  editor.ReadOnly = false
  editor:ClearAll()
  editor:AddText(MSG.Title.."\n"..Underline(MSG.Title).."\n")
  editor:AddText("Status: "..msg.."\n\n")
  DrawBoard(t)
  editor:AddText("\n"..STR.ToolBar.."\n"..MSG.Help)
  editor.ReadOnly = true
end

------------------------------------------------------------------------
-- main routine, processes double-clicks
------------------------------------------------------------------------
local function TicTacClick(ch)
  local BEG = 4                         -- first line of board
  if not buffer[STR.Sig] then return end-- verify buffer signature
  --------------------------------------------------------------------
  -- check appearance of board
  --------------------------------------------------------------------
  local tln = editor:GetLine(0) or ""   -- verify title signature
  if string.sub(tln, 1, string.len(MSG.Title)) ~= MSG.Title then
    Error(MSG.BadBoard) return true
  end
  local LineType = function(ln)         -- classify TTT line
    local text = editor:GetLine(ln)
    if text == nil then return 0
    elseif string.find(text, STR.HorizRegex) then return 1
    elseif string.find(text, STR.TrioRegex) then return 2
    else return 0 end
  end
  local id = ""                         -- verify board pattern
  for i = BEG, BEG+4 do id = id..tostring(LineType(i)) end
  if id ~= STR.BoardPat then Error(MSG.BadBoard) return true end
  --------------------------------------------------------------------
  -- extract board information
  --------------------------------------------------------------------
  local IsXOrO = function(c)            -- classify pieces
    if c == nil or c == "" then return 0
    elseif string.upper(c) == "O" then return O
    elseif string.upper(c) == "X" then return X
    else return -1
    end
  end
  local GetData = function(ln)          -- extract data from a line
    local text = editor:GetLine(ln)
    local _, _, c1, c2, c3 = string.find(text, STR.TrioRegex)
    return IsXOrO(c1), IsXOrO(c2), IsXOrO(c3)
  end
  local t = {}                          -- convert pieces to data
  t[7], t[8], t[9] = GetData(BEG+1)
  t[4], t[5], t[6] = GetData(BEG+3)
  t[1], t[2], t[3] = GetData(BEG+5)
  local delta = 0
  for i = 1,9 do                        -- verify board contents
    if t[i] == -1 then Error(MSG.BadPieces) return true
    elseif t[i] == O then delta = delta - 1
    elseif t[i] == X then delta = delta + 1
    end
  end
  if math.abs(delta) > 1 then Error(MSG.BadPieces) return true end
  --------------------------------------------------------------------
  -- decode user-clicked position or keypresses
  --------------------------------------------------------------------
  if ch == "click" then                 -- mouse double-click event
    local pos = editor.CurrentPos
    local ln = editor:LineFromPosition(pos)
    local col = editor.Column[pos]
    local bln = editor:GetLine(ln) or ""
    tln, id = BUT[ln], nil              -- check for button click
    if not tln then return end
    for i,b in ipairs(tln) do
      if col >= b[1] and col <= b[2] then id = b[3] end
    end
    if not id then return true end      -- nothing happen if no button
  else                                  -- keypress event
    id = string.find("123456789 nN", ch, 1, 1)
    if not id then return true end
    if id == 10 then id = "Autoplay"
    elseif id >= 11 then id = "NewGame"
    end
  end
  --------------------------------------------------------------------
  -- interactive game logic, takes id and t as state inputs
  --------------------------------------------------------------------
  local msg
  if id == "NewGame" then                               -- new game
    t = {}
    msg = ComputerStart(t)
  elseif AnyWin(t) then msg = MSG.AlreadyEnd            -- already won
  elseif MoveCount(t) == 9 then msg = MSG.NoMoves       -- draw
  else
    if id == "Autoplay" then                            -- auto play
      Evaluate(t, X)
    else                                                -- human play
      id = id+0
      if t[id] ~= 0 then Refresh(t, MSG.IllegalMove) return true end
      t[id] = X
    end
    if CheckForWin(t, X) then msg = MSG.HumanWin        -- human moves
    elseif MoveCount(t) == 9 then msg = MSG.NoMoves
    else
      Evaluate(t, O)                                    -- computer moves
      if CheckForWin(t, O) then msg = MSG.ComputerWin
      elseif MoveCount(t) == 9 then msg = MSG.NoMoves
      end
    end
  end
  Refresh(t, msg)                                       -- redraw screen
  return true
end

-- handle incoming events
local function HandleClick() return TicTacClick("click") end
local function HandleChar(c) return TicTacClick(c) end

------------------------------------------------------------------------
-- game initialization (opens a new file and set up handlers)
------------------------------------------------------------------------
function TicTacToe()
  scite_OnClick(HandleClick)
  scite_OnDoubleClick(HandleClick)
  scite_OnChar(HandleChar)
  scite.Open("")
  buffer[STR.Sig] = true;
  local t = {}
    scite.MenuCommand(IDM_MONOFONT)
  Refresh(t, ComputerStart(t))
end

-- end of script