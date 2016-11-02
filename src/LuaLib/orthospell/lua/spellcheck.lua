-- spellcheck.lua - 2010/03/19 --

-- Other SciTE lua spell checkers:
--  <http://natowelch.livejournal.com/392888.html>
--  <http://source.contextgarden.net/context/data/scite/scite-ctx.lua>
--  <http://code.google.com/p/scitelatexide>: myspellchecking.lua

-- TODO:
-- * file type dependent word splitting; checking only comments for code
-- * adding words to a user dictionary (can load with hunspell.add_dic())

-- on Windows, DLL should just be placed in same folder as scite.exe; this is
--  less practical on linux, so also look for shared lib in scite home (/usr/share/scite)
local default_dictpath = props["SciteDefaultHome"].."\\";  -- assuming windows
if(string.match(package.cpath, ".so")) then
  package.cpath = package.cpath..";"..props["SciteDefaultHome"].."/?.so";
  default_dictpath = "/usr/share/hunspell/"  -- assuming hunspell dict package installed
end
require("hunspell");  -- assuming hunspell.dll in SciTE folder
-- if spell.dictpath isn't set, we assume .aff and .dic in SciTE folder
local dictpath = scite_GetProp("spell.dictpath", default_dictpath);
local dictname = scite_GetProp("spell.dictname", "en_US");
hunspell.init(dictpath..dictname..".aff", dictpath..dictname..".dic");

-- set locale
--os.setlocale("Russian");
--print(os.setlocale());  -- print new locale

--- General options
local spell_testword = false;  -- set to false to skip check, otherwise, should be a valid word
local spell_indic = 2;  -- indicator number for marking words (modern, not style byte type)

--- Word extraction options
local spell_ignoreCAPS = true;  -- ignore CamelCase, ALLCAPS?
-- punctuation characters; %p includes some chars we may not want...
-- '+': strip any number of trailing punctuation chars
local spell_pchars = "[%,%.%;%:%/%?%\'%\"%!]+";
local spell_leadingpchars = "[%\'%\"]+";  -- leading chars to strip (false for none)


-- simple word extraction iterator: looks for runs of
--  letters separated by anything besides a letter
function Get_words_simple(alltext)
  local wstart, wstop, word = 0, 0, nil;
  return function ()
    while true do
      wstart, wstop, word = string.find(alltext, "(%a+)", wstop+1);
      if not wstart then
        return nil;
      elseif spell_ignoreCAPS and string.find(word, "%u", 2) then
        --print("Ignoring "..word);
      else
        return word, wstart;
      end --if
    end -- while
  end -- function
end


-- more complicated word extraction: searches for runs of chars
--  separated by whitespace (and a few other delims), then ignores
--  them if they contain anything besides letters
-- goal is to ignore URLs and code as much as possible; far from
--  perfect, but seems to work reasonably well for LaTeX and markdown.
function Get_words(alltext)
  local wstart, wstop, word = 0, 0, nil;
  return function ()
    while true do
      -- to do a better job of ignoring URLs, drop "%/" and "%-" here
      -- add "%<%>" for better behavior with HTML
      wstart, wstop, word = string.find(alltext, "([^%s%-%(%)%/]+)", wstop+1);
      if not wstart then
        return nil;
      end
      -- strip trailing and, optionally, leading punctuation chars
      word = string.gsub(word, spell_pchars.."$", "");
      if spell_leadingpchars then
        local oldword = word;
        word = string.gsub(oldword, "^"..spell_leadingpchars, "");
        wstart = wstart + string.len(oldword) - string.len(word);
      end
      -- skip word if any remaining chars are not %a (or ')
      -- and optionally if word is CamelCase or ALL CAPS
      if string.find(word, "[^%a%']")
       or ( spell_ignoreCAPS and string.find(word, "%u", 2) ) then
        --print("Ignoring "..word);
        --continue;
      else
        return word, wstart;
      end --if
    end -- while
  end -- function
end


-- style byte indicators (using INDICS_MASK, StartStyling, etc.) don't work
--  for some file types, HTML for example (conflict with syntax highlighter?)
function Highlight_range(pos, len)
  editor.IndicatorCurrent = spell_indic;
  editor:IndicatorFillRange(pos, len);
end


-- treat spelling checking as a (per-buffer) toggable mode
-- Need a big file for speed testing (1T3V.pdb = 4 - 5 sec, ignore caps)
--  local spell_start_time = os.time();
--  print("Spell check time:", os.time() - spell_start_time);

function Inline_spell()
  if buffer["SpellMode"] then
    -- clear indicator styling for whole file
    editor.IndicatorCurrent = spell_indic;
    editor:IndicatorClearRange(0, editor.TextLength);
    buffer["SpellMode"] = false;
    return;
  elseif spell_testword and not hunspell.spell(spell_testword) then
    -- if dict path is wrong, spell() will return false for every word
    print("Error: hunspell not initialized. Dictionary files may be missing: "..dictpath.."\\"..dictname..".dic,.aff");
    return;
  end
  buffer["SpellMode"] = true;
  -- without this call to Colourise, syntax highlighting will be broken
  -- in regions which haven't been displayed since document was opened
  editor:Colourise(1, -1);
  local alltext = editor:GetText();
  for word, wstart in Get_words(alltext) do
    --print("Checking: ", word);
    if not hunspell.spell(word) then
      Highlight_range(wstart-1, string.len(word));
    end
  end
end


-- Words manually corrected will retain styling (e.g. red underline) for
--  letters not edited; only way I can think of around this is to monitor
--  OnChar, which I don't really want to do.
-- Only problem with using autocomplete (instead of a user list)
--  seems to be that if misspelled word is prefix of a suggestion,
--  that suggestion is highlighted instead of the first one; also,
--  with a user list, we could have an "add to dict" option

-- Using Indicator(Start/End) instead of Word(Start/End)Position gives better
--  agreement between highlighted word and word used for generating suggestions
-- A remaining problem is that double-clicking jumps cursor to end of word,
--  so we've added a tools menu command to show suggestions without double-clicking

function Spell_suggest()
  if not buffer["SpellMode"] or editor:AutoCActive() then return false; end

  -- normally, autocomplete list will be hidden if word is not prefix
  --  of (any? all?) item on list.
  editor.AutoCAutoHide = false;
  local pos = editor.CurrentPos;
  local startPos = editor:IndicatorStart(spell_indic, pos-1);  --editor:WordStartPosition(pos, true);
  local endPos = editor:IndicatorEnd(spell_indic, pos-1);  --editor:WordEndPosition(pos, true);
  local word = editor:textrange(startPos, endPos);
  --print("Checking word "..word);
  if editor:IndicatorValueAt(spell_indic, pos-1) ~= 0 and not hunspell.spell(word) then
    -- selection determines what will be replaced by suggestion
    editor:SetSel(startPos, endPos);
    local sug = hunspell.suggest(word);
    if #sug > 0 then
      editor:AutoCShow(string.len(word), table.concat(sug, " "));
    end
  end
  -- suppress other handlers in spell check mode; This
  --  only works for handlers added after this one!
  return true;
end


scite_OnDoubleClick(Spell_suggest);
-- set keyboard shortcut here
scite_Command("Toggle Spelling|Inline_spell|F9");
-- alternative to double-clicking to bring up suggestions
scite_Command("Spell Suggestions|Spell_suggest|Shift+F9");


function close_hunspell()
  --print("Closing Hunspell");
  hunspell.close();
end
--scite_Command("Close Hunspell|close_hunspell|");
