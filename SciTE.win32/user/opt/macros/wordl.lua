-- Wordle für SciTE
-- 25.04.2025 by ThorstenK arjunae@nurfuerspam.de
-- This script can be installed to a shortcut using properties:
--     command.name.8.*=wordle
--     command.subsystem.8.*=3
--     command.8.*=wordl
--     command.save.before.8.*=2
-- If you use extman, you can do it in Lua like this:
--     scite_Command('wordle|wordl|Ctrl+8')

-- Automatisch nach 5 Buchstaben bestätigen
local AUTO_CONFIRM = true

local WORDS = {
  "APPLE", "BRAVE", "CRANE", "DREAM", "EAGLE", "FLAME", "GRAPE", "HAPPY", "IDEAL", "JELLY",
  "KNOCK", "LEMON", "MAGIC", "NOBLE", "OCEAN", "PLANT", "QUEEN", "RIDER", "STONE", "TABLE",
  "UNION", "VIVID", "WRIST", "XENON", "YOUNG", "ZEBRA", "ADORE", "BLUSH", "CLOWN", "DAISY",
  "EMBER", "FROST", "GLIDE", "HOVER", "IRONY", "JOKER", "KNEEL", "LUNAR", "MIRTH", "NERDY",
  "OUNCE", "PIANO", "QUILT", "RISKY", "SUGAR", "TIGER", "ULTRA", "VOWEL", "WALTZ", "XYLEM",
  "YIELD", "ZESTY", "ANGEL", "BEACH", "CLEAR", "DRAMA", "EVOKE", "FLAIR", "GRASP", "HONEY",
  "INBOX", "JOLLY", "KOALA", "LATCH", "MANGO", "NERVE", "OXIDE", "PRIDE", "QUEST", "ROBIN",
  "SHINY", "TORCH", "URBAN", "VIGOR", "WHALE", "XEROX", "YACHT", "ZONAL", "AMBER", "BLOOM",
  "CANDY", "DROVE", "ELITE", "FABLE", "GLOOM", "HASTE", "INDEX", "JAZZY", "KARMA", "LIVER",
  "MOTTO", "NICHE", "OMEGA", "PRESS", "QUIET", "RUMOR", "SPICE", "TRACK", "UNITE", "VOICE", "WITCH"
}

local SECRET = WORDS[math.random(#WORDS)]
local GUESSES = {}
local MAX_TRIES = 6
local GAME_OVER = false
local currentInput = ""

-- Stylefarben setzen
local function ColorStyles()
  editor.Lexer = SCLEX_CONTAINER
  editor:StyleClearAll()

  -- Schriftgröße für alle Styles setzen
  for i = 0, 31 do
    editor["StyleSize"][i] = 14
    editor["StyleFont"][i] = "Courier New" -- Monospaced Font
  end

  editor["StyleFore"][1] = 0x00CC00 -- grün
  editor["StyleFore"][2] = 0xFFAA00 -- gelb
  editor["StyleFore"][3] = 0xAAAAAA -- grau
end

-- Bewertung eines Worts
local function StyleWord(guess, secret)
  local styled = {}
  local used = {}

  for i = 1, 5 do
    if guess:sub(i,i) == secret:sub(i,i) then
      styled[i] = {char = guess:sub(i,i), style = 1}
      used[i] = true
    end
  end

  for i = 1, 5 do
    if not styled[i] then
      local ch = guess:sub(i,i)
      local found = false
      for j = 1, 5 do
        if not used[j] and secret:sub(j,j) == ch then
          found = true
          used[j] = true
          break
        end
      end
      styled[i] = {char = ch, style = found and 2 or 3}
    end
  end

  return styled
end

--  Buchstabenübersicht eingefärbt anzeigen
local function DrawLetterStatus()
  local letterStyles = {} -- z. B. A=1 (grün), B=2 (gelb), C=3 (grau)

  for _, guess in ipairs(GUESSES) do
    local styled = StyleWord(guess, SECRET)
    for i = 1, #styled do
      local ch = styled[i].char
      local style = styled[i].style
      local current = letterStyles[ch]

      -- Style-Priorität: 1 (grün) > 2 (gelb) > 3 (grau)
      if not current or style < current then
        letterStyles[ch] = style
      end
    end
  end

editor:AddText("\nNoch uebrig: ")
for c = string.byte("A"), string.byte("Z") do
  local ch = string.char(c)
  local style = letterStyles[ch] or 0

  -- Fügt Buchstabe ein mit korrekt gesetztem Style
  editor:AddText(ch)
  editor:StartStyling(editor.CurrentPos - 1, 31)
  editor:SetStyling(1, style)

  -- Danach normales Leerzeichen (nicht gestylt)
  editor:AddText(" ")
end
editor:AddText("\n")
  editor:AddText("\n")
end


-- Anzeige neu zeichnen
local function Refresh()
  editor.ReadOnly = false
  editor:ClearAll()

  editor:AddText("Wordle: Errate das 5-Buchstaben-Wort\n\n")

  for _, guess in ipairs(GUESSES) do
    local styled = StyleWord(guess, SECRET)
    for _, s in ipairs(styled) do
      editor:AddText(s.char)
      editor:StartStyling(editor.CurrentPos - 1, 31)
      editor:SetStyling(1, s.style)
    end
    editor:AddText("\n")
  end

  if not GAME_OVER then
    editor:AddText("\n> " .. currentInput .. "\n")
    editor:GotoPos(editor.Length)
  else
    editor:AddText("\n")
    if GUESSES[#GUESSES] == SECRET then
      editor:AddText("\n🎉 Gewonnen! Das Wort war: " .. SECRET .. "\n")
    else
      editor:AddText("\n❌ Verloren! Das Wort war: " .. SECRET .. "\n")
    end
    editor:AddText("\nDruecke N für ein neues Spiel.")
  end

  if #GUESSES > 0 then
    DrawLetterStatus()
  end
end

-- Neues Spiel starten
local function NewGame()
  SECRET = WORDS[math.random(#WORDS)]
  GUESSES = {}
  currentInput = ""
  GAME_OVER = false
  Refresh()
end

-- Eingabe verarbeiten
local function OnChar(c)
  if GAME_OVER then
    if c == "n" or c == "N" then
      NewGame()
    end
    return true
  end

  if c == "\n" or c == "\r" then
    if #currentInput == 5 then
      table.insert(GUESSES, currentInput:upper())
      currentInput = ""
      if GUESSES[#GUESSES] == SECRET or #GUESSES >= MAX_TRIES then
        GAME_OVER = true
      end
    end
  elseif c:match("%a") and #currentInput < 5 then
    currentInput = currentInput .. c:upper()
    if AUTO_CONFIRM and #currentInput == 5 then
      table.insert(GUESSES, currentInput)
      currentInput = ""
      if GUESSES[#GUESSES] == SECRET or #GUESSES >= MAX_TRIES then
        GAME_OVER = true
      end
    end
  elseif c == "\b" then
    currentInput = currentInput:sub(1, -2)
  end

  Refresh()
  return true
end

local function wordle()
	-- Initialisierung
	scite_OnChar(OnChar)
	scite.Open("")
	ColorStyles()
	NewGame()
end

wordle()
