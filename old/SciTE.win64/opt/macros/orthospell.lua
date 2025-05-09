-- orthospell.lua for SciTE
-- Author: Urs Eberle
-- Based on: Matt White's luahunspell <http://luahunspell.googlecode.com>
-- Version: 1.1.0  -  October 2014
-- Website: tools.diorama.ch
-- OS: Windows (for Linux changes must be made)

-- In order to work, the following files are necessary:
--   - 'hunspell.dll' get it from 'https://code.google.com/p/luahunspell/downloads/list'
--   - 'gui.dll'
--   - 'extman.lua'; not all versions work with orthospell! Download it from
--      tools.diorama.ch (the version recommended by Matt White will work too)
--  The dll libraries must be placed into the SciTE root directory (arjunae: no need to. statically linked lib )
--  orthospell.lua must be placed into the scite_lua directory
--  extman.lua must be placed into the SciTE root directory
--  The following line must be written into SciTE's user.properties file
--      ext.lua.startup.script=$(SciteDefaultHome)\extman.lua
--  The following lines are optional:
--      spell.dictname=<hunspell dict names> e.g. de_DE|en_US|fr-classique ; default: en_US
--      spell.dictpath=$(SciteDefaultHome)\<directory> default: SciTE root directory

-- arjunae:Nov16 - switch to orthospell.home with package.loadlib. (was require("hunspell"))

-- global variables
local sciteHome = props["SciteUserHome"]
local dictpath = scite_GetProp("spell.dictpath", sciteHome)
local userdict = scite_GetProp("spell.userdict", nil)
local dictlist = split(scite_GetProp("spell.dictname", "en_US"),"|")
local dictname = dictlist[1]
local dictCP
local dictlang
local ignoreCAPS = true -- default
local spellIndic = 2
local isoChars
local utfChars
local langChars
local cpMode
local wordRegEx
local dicInit = false
local hspell = false
local toDic, toDoc = true , false
local spChars
local spellChars = props["chars.alpha"]..props["chars.accented"]
local txtChars, htmlChars, texChars
local allText
local ortho = os.getenv("temp").."\\ortho.dic"

-- begin of customization (define your additions and changes here)

-- the following intercept functions allow you to make lexer- or language-dependent
-- changes to the standard processing without changing the main program.
-- place your functions into the corresponding section further down

-- text for the SciTE menu, use utf-8

local toggleSpell = "Toggle Spelling"

local lang = {}
	lang["en_US"] = "English US"
	lang["en-GB"] = "English UK"
	lang["de_DE"] = "Deutsch"
	lang["de_CH"] = "Deutsch CH"
	lang["fr-classique"] = "FranÃ§ais classique"
	lang["es_ES"] = "EspaÃ±ol"
	lang["it_IT"] = "Italiano"


function get_language(dic)
	if lang[dic] then lng = lang[dic]
	else lng = dic end
	return lng
end
function get_langParam(dn)
-- Language settings
	dictCP = "iso"     -- default dictionary code page, redefine below if necessary (see French)
	isoChars = "%aÀ-ÿ" -- equal to ISO 8859-1 (Latin 1); redefine in the language section if necessary;
	utfChars = "%a\128-\191\195-\212"  -- UTF-8 up to U+053F (Cyrillic); redefine in the language section if necessary;
	langChars = ""      -- special characters for individual languages such as hyphens and apostrophes
						-- if your ISO 8859-x has letters in the range of 161(xA1) to 191(xBF), add them to langChars
	if dn == "en_US" then
		langChars = "-'"
	elseif dn == "de_DE" then
		langChars = "-"
	elseif dn == "de_CH" then
		langChars = "-"
	elseif dn == "fr-classique" then
		dictCP = "utf"
		langChars = "'’"
	elseif dn == "en-GB" then
		langChars = "-'"
	elseif dn == "it_IT" then
		langChars = "'"
	end
	dictlang = string.sub(dn,1,2)
	props["spell.dictlang"] =  get_language(dn) -- display dictionary in status bar (must be defined)
end

function add_userDict()
	if not scite_FileExists(userdict) then
		print ("The user dictionary '"..userdict.."' does not exist")
	else
		indic  = io.open(userdict, "r")
		if indic then
			local t = indic:read("*all")
			indic:close()
			local outdic = io.open(ortho,"w")
			outdic:write("999\n")
			outdic:write(t)
			outdic:close()
			hunspell.add_dic(ortho)
		else
			print("User dictionary: '"..userdict.."' is a directory and not a file")
		end
	end
end

function intercept_text (txt) -- txt ~ allText
-- pre-spellcheck preparation of the document
	if editor.Lexer == 4  then   -- HTML
		txt = strip_HTML (txt)
	elseif editor.Lexer == 14 or editor.Lexer == 49 then -- LaTeX or TeX
		txt = strip_TeX(txt)
	end
	return txt
end

function intercept_word (at,wd,ws,wl) -- ~ allText, word, wstart, wlen
-- check and change word before it is spell-checked
	if editor.Lexer == 4 then -- HTML
		wd = string.gsub(wd,"xaxax","") -- remove soft hyphen substitute
	end
	return wd, ws, wl
end

function intercept_spellError (at,wd,ws,wl) -- ~ allText, word, wstart, wlen
-- if hunspell did not recognize the word, check if it is a special case such as
-- a character with several meanings (e.g. ' can be an apostrophe or a single quote)
-- you can then either drop it or check the modified word again. If such a case is rare
-- (e.g single quotes), then this is more economical then checking with intercept_word.
-- !! ws and wl MUST be returned by your function; check that wl is not nil before calling it!
-- !! return wl as nil if word was found to be correct
	if string.match(langChars,"-") then
		ws, wl = check_hyphenation(wd,ws,wl)
	end
	if wl and string.match(langChars,"'") then -- check for single quote
		ws, wl = check_singleQuote(wd,ws,wl)
	end
	if dictlang == "de" and  wl and wl < 6 then -- German specific
		ws, wl = check_abbrivDot (at, wd, ws, wl)
	end
	return ws, wl
end

function intercept_suggestion(sp, ep, wd) -- ~ startPos, endPos, word
	if editor.Lexer == 4  and check_softHyphen(sp, ep,wd) then
		return true
	end
	return false
end

-- end of customization

-- beginn main

if not gui then  -- if not the extman.lua is used that comes with Orthospell
	require ("gui")
end

-- Arjunae --  changed to loadlib and require as a fallback to be more flexible
if not scite_FileExists(props["orthospell.home"].."\\hunspell.dll") then end

-- using statically linked hunspell, which can reside anywhere - so just do...
if not scite_FileExists(dictpath.."\\"..dictname..".aff") then
		print ("Orthospell: The dictionary "..dictname.." is not installed")
else
	local fnInit, err =package.loadlib(props["orthospell.home"].."\\hunspell.dll",'luaopen_hunspell')
	if err~=NULL then 
		--print("Orthospell: hunspell.dll not found or orthospell.home unset. Trying to require...")
		status, hunspell = pcall(require,"hunspell")
		if (type(hunspell) ~= "table")  then end --print("Hunspell not found via require.") end
	else		
		assert(type(fnInit) == "function", err)
		fnInit()
	end
end

--Hunspell should be loaded and initialized by now.
if (type(hunspell) == "table") then 
hspell = true
	hunspell.init(dictpath.."\\"..dictname..".aff", dictpath.."\\"..dictname..".dic")
	-- adding a user dictionary
	if userdict then add_userDict() end
	get_langParam(dictname)
	dicInit = true
else
--print ("error loading Hunspell")
end
	
-- adding a user dictionary
if userdict then add_userDict() end
get_langParam(dictname)
dicInit = true

function inline_spell()
	if not dicInit then print ("No dictionary loaded!") return end
	if buffer["SpellMode"] then
		reset_page()
		return
	end
	buffer["SpellMode"] = true
	cpMode = get_cpMode()
	spChars = pcall(set_wordChars)  -- use a character set that suits natural languages
	wordRegEx = create_regEx()
	editor:Colourise(1, -1)
	allText = editor:GetText()
	allText = intercept_text(allText) -- prepare the document before spell-checking
	for word, wstart in get_words(allText) do
		local wlen = string.len(word)
		word, wstart, wlen = intercept_word(allText, word, wstart, wlen) -- edit word before spell-checking
		word = check_codePage(word,toDic) -- change encoding if necessary
		if not hunspell.spell(word) then
			wstart, wlen = intercept_spellError(allText, word, wstart, wlen) -- check special cases
			if (wlen) then highlight_range(wstart-1, wlen) end
		end
	end
end

function get_words(allText)
	local wstart, wstop, word = 0, 0, nil
	return function ()
		while true do
			wstart, wstop, word = string.find(allText, wordRegEx, wstop+1)
			if not wstart then
				return nil
			elseif ignoreCAPS and string.match(word, "%u%u") then
			else
				return word, wstart
			end
		end
	end
end

function spell_suggest()
	if not buffer["SpellMode"] or editor:AutoCActive() then return false end
	editor.AutoCAutoHide = false
	local pos = editor.CurrentPos-2
	local indicator = editor:IndicatorValueAt(spellIndic,pos)
	if indicator == 0 then
		pos = editor.Anchor + 1
		indicator = editor:IndicatorValueAt(spellIndic,pos)
	end
	if indicator > 0 then
		local startPos = editor:IndicatorStart(spellIndic, pos)
		if  cpMode > 1 then
			startPos = check_posUTF(startPos)
		end
		local endPos = editor:IndicatorEnd(spellIndic, pos)
		local word = editor:textrange(startPos,endPos)
		if intercept_suggestion(startPos, endPos, word) then return false end
		if  not hunspell.spell(word) then
			editor:SetSel(startPos, endPos)
			local wlen = string.len(word)
			word = check_codePage(word,toDic)
			local sug = hunspell.suggest(word)
			if #sug > 0 then
				local sugstr = table.concat(sug, " ")
				sugstr = check_codePage(sugstr,toDoc) -- change encoding if necessary
				editor.AutoCSeparator = 32
				editor:AutoCShow(wlen,sugstr)
			end
		end
	end
	return true
end
-- end main

-- functions to be called by intercept_text

function strip_HTML(txt)
-- replace stylesheets with blanks
	txt = string.gsub(txt, "<style.-</style>", function (w)
		return string.rep(" ",string.len(w))
		end)
-- replace scripts with blanks
	txt = string.gsub(txt, "<script.-</script>", function (w)
		return string.rep(" ",string.len(w))
		end)
-- replace tags with blanks
	txt = string.gsub(txt, "<.->", function (w)
		return string.rep(" ",string.len(w))
		end)
-- substitute &shy; entity with a string of (meaningless) letters
	txt = string.gsub(txt, "&shy;", "xaxax")
-- replace HTML entities with blanks
	txt = string.gsub(txt, "&%a-;", function (w)
		return string.rep(" ",string.len(w))
		end)
	return txt
end

function strip_TeX(txt)
-- replace commands with blanks
	txt = string.gsub(txt, "\\[^{%s]+", function (w)
		return string.rep(" ",string.len(w))
		end)
	-- Note: if you want to exclude text within curly brackets, change within the
	-- regEx the opening curly bracket to a closing one ("\\[^}%s]+")
	return txt
end

-- end functions intercept_text

-- functions to be called by intercept_word
	-- empty
-- end intercept_word functions


-- functions to be called by intercept_spellError

function check_hyphenation(wd, ws, wl)
-- skip word if it consists of hyphens only
	if string.find(wd,"^[%-]+$") then
		return ws, nil
	end
	return ws, wl
end

function check_singleQuote (wd, ws, wl)
-- check if the word is preceded or followed by a single quote and check again
	a1, wd, a2 =  string.match(wd, "^('?)(.-)('?'?)$")
	if a1 ~= "" or a2 ~= "" then
		if not hunspell.spell(wd) then
			return ws + string.len(a1), wl - string.len(a1) - string.len(a2)
		else
			return ws, nil -- meaning: word is correct
		end
	end
	return ws, wl
end

function check_abbrivDot (at, wd, ws, wl)
--	look ahead: the German dict requires the final dot in abbreviations
	local pos = ws + wl
	if string.sub(at,pos,pos)== "." then
		if not hunspell.spell(wd..".") then
			local fl = string.sub(at,pos+2,pos+2)
			if not string.match(fl, "%u") then wl = wl + 1
		end
		else
			return nil -- meaning: word is correct
		end
	end
	return ws, wl
end

-- end intercept_spellError functions


-- functions to be called by intercept_suggestion

function check_softHyphen(sp, ep, wd)
-- if the word contains soft hyphens, then show the plain word instead of suggestions
	if string.find(wd,"&shy;") then
		editor:SetSel(sp, ep)
		editor:AutoCShow(string.len(wd),"="..string.gsub(wd, "&shy;", ""))
		return true
	else return false
	end
end
-- end function intercept_suggestion

function get_cpMode()
-- determine code page of document and dictionary
-- mode: 0 = iso iso, 1 = iso utf, 2 = utf iso, 3 = utf utf
	local mode = 0
	if editor.CodePage == 65001 then mode = 2 end
	if dictCP == "utf" then mode = mode + 1 end
	return mode
end

function check_codePage(str,to)
-- convert to or from utf-8
		if cpMode == 2 then -- utf iso
			if to == toDic then
				str = gui.from_utf8 (str)
			else
				str = gui.to_utf8(str)
			end
		elseif cpMode == 1  then -- iso utf
			if to == toDic then
				str = guiComWeb.lua.to_utf8(str)
			else
				str = gui.from_utf8(str)
			end
		end
	return str
end

function set_wordChars()
-- the new character set does not directly affect spell checking. It may change,
-- however, what is highlighted if you double-click on a word. The new behaviour is:
-- accented characters are treated as word characters, wheras numbers are not
	if editor.Lexer == 0 then
		txtChars = editor.WordChars
	elseif editor.Lexer == 4 then
		htmlChars = editor.WordChars
	elseif editor.Lexer == 14 then
		texChars = editor.WordChars
	elseif editor.Lexer == 49 then
		texChars = editor.WordChars
	else return
	end
	editor.WordChars = spellChars..langChars
end

function reset_wordChars()
-- the original character set is restored
	if editor.Lexer == 0 then
		editor.WordChars = txtChars
	elseif editor.Lexer == 4 then
		editor.WordChars = htmlChars
	elseif editor.Lexer == 14 then
		editor.WordChars= texChars
	elseif editor.Lexer == 49 then
		editor.WordChars = texChars
	end
end

function create_regEx()
-- creates the regular expression for the word search
	local wreg = "(["
	local lngReg = string.gsub(langChars,"%-","%%-")
	if cpMode > 1 then  -- document is UTF-8
		wreg = wreg..utfChars..gui.to_utf8(lngReg)
	else
		wreg = wreg..isoChars..lngReg
	end
	return wreg.."]+)"
end

function check_posUTF(sp)
-- correct start position for UTF-8 chars starting with byte c2
	if string.sub(allText,sp,sp) == "Â" then
		sp = sp + 1
	end
	return sp
end

function change_dict(nr)
 -- change the current dictionary
	reset_page()
	local old_dict = dictname
	dictname = dictlist[tonumber(nr)]
	if not scite_FileExists(dictpath.."\\"..dictname..".aff") then
		print ("The dictionary "..dictname.." is not installed")
		dictname = old_dict
	else
		get_langParam(dictname)
		hunspell.init(dictpath.."\\"..dictname..".aff", dictpath.."\\"..dictname..".dic")
		hunspell.add_dic(ortho)
		dicInit = true
	end
end

function highlight_range(pos, len)
	editor.IndicatorCurrent = spellIndic
	editor:IndicatorFillRange(pos, len)
end

function reset_page()
	editor.IndicatorCurrent = spellIndic
	editor:IndicatorClearRange(0, editor.TextLength)
	if spChars then reset_wordChars() end
	buffer["SpellMode"] = false
end

-- menu creation

--[[
if (hspell) then
	local ext, shtct = "", ""
	if props["file.patterns.spell"] ~= "" then
		ext = "|$(file.patterns.spell)"
		shtct = "|nil"
	end
	if scite_GetProp("spell.contextmenu", "0") == "1" then
		scite_Command(toggleSpell.."|inline_spell|Context")
	else
		--scite_Command(toggleSpell.."|inline_spell|Context")
		--scite_Command(toggleSpell.."|inline_spell"..ext.."|F12")
	end
	if dictlist[2] then
		for i in ipairs(dictlist) do
			flang = get_language(dictlist[i])
			if not scite_FileExists(dictpath.."\\"..dictlist[i]..".aff") then
				print ("The dictionary "..dictlist[i].." is not installed")
			else
				scite_Command(flang.."|change_dict "..i..ext..shtct)
			end
		end
	end
	scite_OnDoubleClick(spell_suggest)
end
--]]

if dictlist[2] then
	for i in ipairs(dictlist) do
		flang = get_language(dictlist[i])
		if not scite_FileExists(dictpath.."\\"..dictlist[i]..".aff") then
			print ("The dictionary "..dictlist[i].." is not installed")
		else
			scite_Command(flang.."|change_dict "..i..ext..shtct)
		end
	end
end

-- Marcedo: adapted for use with myScites MacroScripts feature
scite.StripShow("!'HunSpell listening '(&Toggle Spelling)(&Close)")

function OnStrip(control, change)
	
	if control == 1 then --Start Spelling
		inline_spell()
		scite_OnDoubleClick(spell_suggest)
	end

	if control == 2 then --Quit 	
		reset_page()
		scite.StripShow("") -- hide the dialog
	end

end