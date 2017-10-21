------------------------------------------------------------------------
-- Joseph Weizenbaum's classic Eliza ported to SciTE Version 2
-- Kein-Hong Man <khman@users.sf.net> 20060905
-- This program is hereby placed into PUBLIC DOMAIN
------------------------------------------------------------------------
-- HOW TO USE
-- * This program is for recreational purposes only. :-)
-- * ClassicEliza function will open a new buffer, then type away...
-- * Eliza recognizes one line of input only (if you are typing very
--   long lines, please consider seeing a real person.)
-- * Eliza will not interfere with other buffers or handlers, and is
--   compatible with extman.
------------------------------------------------------------------------
-- Original ELIZA paper:
--   ELIZA--A Computer Program For the Study of Natural Language
--   Communication Between Man and Machine,
--   Joseph Weizenbaum, 1966, Communications of the ACM Volume 9,
--   Number 1 (January 1966): 36-35.
--   URL: http://i5.nyu.edu/~mm64/x52.9265/january1966.html
------------------------------------------------------------------------
-- A copy of the original BASIC source of this Lua version of ELIZA can
-- be found at Josep Subirana's ELIZA download page.
------------------------------------------------------------------------
-- NOTES
-- * Modifications made to fit the program into SciTE...
-- * For historical accuracy, functionality is more-or-less identical,
--   as is the use of an all upper-case alphabet for output.
-- * There is really no point extending this program. Many other more
--   advanced Eliza-type programs exist. Good candidates for porting are
--   EMACS' doctor.el and Perl's Chatbot-Eliza.
-- * One difference is keyword are matched by iterating through a hash
--   array, so matching order will be different from initialization order.
-- * In order to avoid keeping any internal state, this Eliza does not
--   remember your name.
-- * Input is now case-insensitive.
-- * The original used backticks for apostrophes, this was fixed.
-- * A couple of spelling mistakes in strings and comments fixed.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- constants and primitives
------------------------------------------------------------------------
local SIG = "SciTE_ClassicEliza"

------------------------------------------------------------------------
-- simple check for extman, partially emulate if okay to do so
------------------------------------------------------------------------
if OnChar and not scite_Command then
  Error("There is an OnChar conflict, please use extman")
elseif not scite_OnChar then
  -- simple way to add a handler only, can't remove like extman does
  local _OnChar
  scite_OnChar = function(f) _OnChar = f end
  OnChar = function(c) if _OnChar then return _OnChar(c) end end
end

------------------------------------------------------------------------
-- Eliza main routine, processes user input
-- * Input is case insensitive. No punctuation except apostrophes,
--   as in: don't you're i'm i've you've.
------------------------------------------------------------------------
local function Eliza(text)
  local response = ""
  local user = string.upper(text)
  local userOrig = user

  -- randomly selected replies if no keywords
  local randReplies = {
    "WHAT DOES THAT SUGGEST TO YOU?",
    "I SEE...",
    "I'M NOT SURE I UNDERSTAND YOU FULLY.",
    "CAN YOU ELABORATE ON THAT?",
    "THAT IS QUITE INTERESTING!",
    "THAT'S SO... PLEASE CONTINUE...",
    "I UNDERSTAND...",
    "WELL, WELL... DO GO ON",
    "WHY ARE YOU SAYING THAT?",
    "PLEASE EXPLAIN THE BACKGROUND TO THAT REMARK...",
    "COULD YOU SAY THAT AGAIN, IN A DIFFERENT WAY?",
  }

  -- keywords, replies
  local replies = {
    [" CAN YOU"] = "PERHAPS YOU WOULD LIKE TO BE ABLE TO",
    [" DO YOU"] = "YES, I",
    [" CAN I"] = "PERHAPS YOU DON'T WANT TO BE ABLE TO",
    [" YOU ARE"] = "WHAT MAKES YOU THINK I AM",
    [" YOU'RE"] = "WHAT IS YOUR REACTION TO ME BEING",
    [" I DON'T"] = "WHY DON'T YOU",
    [" I FEEL"] = "TELL ME MORE ABOUT FEELING",
    [" WHY DON'T YOU"] = "WHY WOULD YOU WANT ME TO",
    [" WHY CAN'T I"] = "WHAT MAKES YOU THINK YOU SHOULD BE ABLE TO",
    [" ARE YOU"] = "WHY ARE YOU INTERESTED IN WHETHER OR NOT I AM",
    [" I CAN'T"] = "HOW DO YOU KNOW YOU CAN'T",
    [" SEX"] = "I FEEL YOU SHOULD DISCUSS THIS WITH A HUMAN.",
    [" I AM"] = "HOW LONG HAVE YOU BEEN",
    [" I'M"] = "WHY ARE YOU TELLING ME YOU'RE",
    [" I WANT"] = "WHY DO YOU WANT",
    [" WHAT"] = "WHAT DO YOU THINK?",
    [" HOW"] = "WHAT ANSWER WOULD PLEASE YOU THE MOST?",
    [" WHO"] = "HOW OFTEN DO YOU THINK OF SUCH QUESTIONS?",
    [" WHERE"] = "WHY DID YOU THINK OF THAT?",
    [" WHEN"] = "WHAT WOULD YOUR BEST FRIEND SAY TO THAT QUESTION?",
    [" WHY"] = "WHAT IS IT THAT YOU REALLY WANT TO KNOW?",
    [" PERHAPS"] = "YOU'RE NOT VERY FIRM ON THAT!",
    [" DRINK"] = "MODERATION IN ALL THINGS SHOULD BE THE RULE.",
    [" SORRY"] = "WHY ARE YOU APOLOGIZING?",
    [" DREAMS"] = "WHY DID YOU BRING UP THE SUBJECT OF DREAMS?",
    [" I LIKE"] = "IS IT GOOD THAT YOU LIKE",
    [" MAYBE"] = "AREN'T YOU BEING A BIT TENTATIVE?",
    [" NO"] = "WHY ARE YOU BEING NEGATIVE?",
    [" YOUR"] = "WHY ARE YOU CONCERNED ABOUT MY",
    [" ALWAYS"] = "CAN YOU THINK OF A SPECIFIC EXAMPLE?",
    [" THINK"] = "DO YOU DOUBT",
    [" YES"] = "YOU SEEM QUITE CERTAIN. WHY IS THIS SO?",
    [" FRIEND"] = "WHY DO YOU BRING UP THE SUBJECT OF FRIENDS?",
    [" COMPUTER"] = "WHY DO YOU MENTION COMPUTERS?",
    [" AM I"] = "YOU ARE",
  }

  -- conjugate
  local conjugate = {
    [" I "] = "YOU",
    [" ARE "] = "AM",
    [" WERE "] = "WAS",
    [" YOU "] = "ME",
    [" YOUR "] = "MY",
    [" I'VE "] = "YOU'VE",
    [" I'M "] = "YOU'RE",
    [" ME "] = "YOU",
    [" AM I "] = "YOU ARE",
    [" AM "] = "ARE",
  }

  -- random replies, no keyword
  local function replyRandomly()
    response = randReplies[math.random(table.getn(randReplies))].."\n"
  end

  -- find keyword, phrase
  local function processInput()
    for keyword, reply in pairs(replies) do
      local d, e = string.find(user, keyword, 1, 1)
      if d then
        -- process keywords
        response = response..reply.." "
        if string.byte(string.sub(reply, -1)) < 65 then -- "A"
          response = response.."\n"; return
        end
        local h = string.len(user) - (d + string.len(keyword))
        if h > 0 then
          user = string.sub(user, -h)
        end
        for cFrom, cTo in pairs(conjugate) do
          local f, g = string.find(user, cFrom, 1, 1)
          if f then
            local j = string.sub(user, 1, f - 1).." "..cTo
            local z = string.len(user) - (f - 1) - string.len(cTo)
            response = response..j.."\n"
            if z > 2 then
              local l = string.sub(user, -(z - 2))
              if not string.find(userOrig, l) then return end
            end
            if z > 2 then response = response..string.sub(user, -(z - 2)).."\n" end
            if z < 2 then response = response.."\n" end
            return
          end--if f
        end--for
        response = response..user.."\n"
        return
      end--if d
    end--for
    replyRandomly()
    return
  end

  -- main()
  -- accept user input
  if string.sub(user, 1, 3) == "BYE" then
    response = "BYE, BYE FOR NOW.\nSEE YOU AGAIN SOME TIME.\n"
    return response
  end
  if string.sub(user, 1, 7) == "BECAUSE" then
    user = string.sub(user, 8)
  end
  user = " "..user.." "
  -- process input, print reply
  processInput()
  response = response.."\n"
  return response
end

------------------------------------------------------------------------
-- OnChar handler, grabs a single line of input only upon [Enter]
------------------------------------------------------------------------
local function ElizaHandler(c)
  if not buffer[SIG] then return end    -- verify buffer signature
  if c == "\n" then                     -- user typed [Enter]
    local lnUser = editor:LineFromPosition(editor.CurrentPos) - 1
    if lnUser < 0 then return end
    -- grab line without ending newlines
    local lbeg = editor:PositionFromLine(lnUser)
    local lend = editor.LineEndPosition[lnUser]
    local text = editor:textrange(lbeg, lend)
    -- perform Eliza text processing
    if text ~= "" then
      editor:AddText(Eliza(text))
    end
  end
  return true
end

------------------------------------------------------------------------
-- script initialization (opens a new buffer and set up handlers)
------------------------------------------------------------------------
function ClassicEliza()
  scite_OnChar(ElizaHandler)
  scite.Open("")
  buffer[SIG] = true;
  editor:AddText([[
WELCOME TO ANOTHER SESSION WITH
YOUR COMPUTER PSYCHIATRIST, ELIZA

IT SURE IS NEAT TO HAVE YOU DROP BY

]])
  editor:DocumentEnd()
  math.randomseed(os.time())
end

-- end of script
