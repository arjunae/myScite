-- AutoComplete by Lexikos. Update 20250430 by Marcedo

--[[
  - Place this file in your SciTE user settings folder.
  - Add the following to UserLuaScript.lua:
        dofile(props['SciteUserHome'].."/AutoCompleteNew.lua")
  - Restart SciTE.
 @info 2025 Marcedo@habMalNeFrage.de 
	- support for reading ctag generated API files props["project.sdk.api"] props["project.session.api"] written by SciTEproject.lua	
	- Support for `keyword::subkeyword` style entries (e.g., `SciteWin::Submit or ::Submit`) 
	- APINames are read onOpen, buffer identifiers are read by onWord and merged dynamically for the suggestion list to use.
	- defined a maximal buffer lenght for the script to handle ( AC_MAX_SIZE ) and a maximum length for UserLists MENUITEMS_MAX
	- a simple trace Mode has been added. DEBUG_MODE=true
	- Cache Data where possible using apiCache[LexerName] and invalidation.
	- Automatically loads props["APIDir"]/{lexerLanguage}.api
]]
local DEBUG_MODE =false

-- Maximal filesize that this script should handle
local AC_MAX_SIZE = 262144 --260k
-- List of styles per lexer where no symbols are collected.
local SCLEX_AHK1 = 200
local SCLEX_AHK2 = 201 --?
local SCLEX_GENERIC = 1024

local IGNORE_STYLES = {
    -- Should include comments, strings and errors.
    [SCLEX_AHK1] = {1, 2, 6, 20},
    [SCLEX_AHK2] = {1, 2, 3, 5, 15},
    [SCLEX_BATCH] = {1, 3},
    [SCLEX_BASH] = {1, 2, 5, 6, 12, 13},
    [SCLEX_CMAKE] = {1, 2, 3, 4, 7},
    [SCLEX_CSS] = {4, 9, 13, 14},
    [SCLEX_COFFEESCRIPT] = {1, 2, 3, 6, 7, 12, 15, 18, 22, 24},
    [SCLEX_CPP] = {1, 2, 3, 6, 7, 8, 12},
    [SCLEX_FREEBASIC] = {1, 4, 9},
    [SCLEX_HASKELL] = {4, 5, 9, 13, 14, 15, 16, 19},
    [SCLEX_HTML] = {1, 2, 3, 6, 7, 8, 12},
    [SCLEX_LUA] = {1, 2, 3, 6, 7, 8, 12},
    [SCLEX_MAKEFILE] = {1, 12},
    [SCLEX_MARKDOWN] = {},
    [SCLEX_PERL] = {1, 2, 6, 7, 22, 23, 24, 25, 26, 27, 44},
    [SCLEX_PYTHON] = {1, 3, 4, 12, 13},
    [SCLEX_RUBY] = {1, 2, 6, 7},
    [SCLEX_RUST] = {1, 2, 3, 4},
    [SCLEX_SPICE] = {8},
    [SCLEX_PROPERTIES] = {1},
    [SCLEX_POWERSHELL] = {1, 2, 3, 13, 16},
    [SCLEX_VHDL] = {1, 2, 4, 7, 14, 15},
    [SCLEX_GENERIC] = {1, 2, 3, 6, 7, 8}
}

-- Names from api files and editor, stored by lexer name.
local apiCache = {} -- Loaded API File Content
local apiLoaded=0 -- Dirty Switch
local textNames = {} -- buffers textNames
local mergedNames = {} -- Current buffers Cache

-- Number of chars to type before the autocomplete list appears:
local MIN_PREFIX_LEN = 4
-- Length of shortest word to add to the autocomplete list:
local MIN_IDENTIFIER_LEN = 4
-- List of regex patterns for finding suggestions for the autocomplete menu:
local IDENTIFIER_PATTERNS = {"[a-z_][a-z_0-9]+"}

-- This feature is very awkward when combined with automatic popups:
props["autocomplete.choose.single"] = "0"

local INCREMENTAL = true
local IGNORE_CASE = false
local CASE_CORRECT = true
local CASE_CORRECT_INSTANT = false
local WRAP_ARROW_KEYS = false
local CHOOSE_SINGLE = props["autocomplete.choose.single"]
local MENUITEMS_MAX = 200 -- Anyone really scrolls further ?

--~~~~~~~~~~~~~~~~~~~~~~~

local names = {}

local notempty = next
local shouldIgnorePos = function(self)
end -- init'd by buildNames().
local normalize

if IGNORE_CASE then
    normalize = string.upper
else
    normalize = function(word)
        return word
    end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Deal with different Path Separators o linux/win
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local dirSep = package.config:sub(1,1)
--
-- returns if a given fileNamePath exists
--
local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- checks for a Value in a Table
-- copes with array like - table[value]=true constructs
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function isInTable(table, elem)
    if table == nil then
        return false
    end
    for k, i in ipairs(table) do
        if k == elem or i == elem then
            return true
        end
    end
    return false
end

local function countAPICache(table, elem)
    local lexer = editor.LexerLanguage
    local count = 0
    if apiCache[lexer] then
        for _ in pairs(apiCache[lexer]) do
            count = count + 1
        end
    end
    return count
end


---
--- Hilfsfunktion für Debug-Ausgaben
---
local function debugPrint(...)
    if DEBUG_MODE then
        print(...)
    end
end
--
-- Disable collection of words in comments, strings, etc.
--
local function setLexerSpecificStuff()
    local iLexer = editor.Lexer

    if type(IGNORE_STYLES[iLexer]) == "nil" and editor.Lexer ~= 1 then -- Performance: Disable Ac for the Null Lexer
    -- print("ac>Current lexer not supported. Using generic Mode.")
    --iLexer=SCLEX_GENERIC
    end
    if IGNORE_STYLES[iLexer] then
        -- Define a function for calling later:
        shouldIgnorePos = function(pos)
            return isInTable(IGNORE_STYLES[iLexer], editor.StyleAt[pos])
        end
    else
        -- Optional: Disable autocomplete popups for unknown lexers.
        shouldIgnorePos = function(pos)
            return true
        end
    end
	-- Override settings that interfere with this script:
	 debugPrint(" Language:  "..editor.LexerLanguage)
	if props["project.inProject"]==1 then 
		props["autocomplete."..editor.LexerLanguage..".start.characters"] = ""
		props["autocomplete."..editor.LexerLanguage..".fillups"] = ""
	else
		props["autocomplete."..editor.LexerLanguage..".start.characters"] = "$(chars.alpha)$(chars.numeric)$.:"
	end
end

--
-- Append current Lexers Api File and the ctags generated one. 
--
-- Load API names into cache for current lexer
local function loadApiNames()
	 if props["project.inProject"]==0 or props["project.inProject"]=="" then return end 
         debugPrint("ac>loadApiNames")

    local lexer = editor.LexerLanguage
    local apiNames = {}
    local paths = props["project.session.api"]..";"..props["APIDir"].."/ac_"..lexer..".api" -- ac_cpp.api
    -- maybe somwhen there will be support for a more structured file format APIdir\{lexerLanguage}.api
	local cnt = 0
    for apiFile in paths:gmatch("[^;]+") do
        debugPrint("ac>loadapinames: reading apiFile " .. apiFile)

        local f = io.open(apiFile)
        if f then
            
            for line in f:lines() do
                -- nicht greedy bis zur ersten klammer, falls fail, dann greedy den ganzen string
                --local name = line:match("^%s*([^)]-%s*%)%s*)")	or line:match("^(.*)") or ""
                local name = line
                --if name:find("GetFile") then print(name) end

                if #name > 0 and name:sub(1, 1) ~= "#" then
						  if DEBUG_MODE==true then	cnt=cnt+1 end
                    apiNames[normalize(name)] = name
                end --# Kommentare
            end
            f:close()
        else
                 debugPrint("ac>ignoring nonExistant apiFile: " .. apiFile)
        end
    end
    apiCache[lexer] = apiNames
	  debugPrint("ac>LoadAPI, APICache["..editor.LexerLanguage.."] contains "..cnt.."Lines"); cnt=0
end



-- BuildNames now only gathers buffers text names
local function buildNames()
         debugPrint("ac>loadEditorNames")
    ---  if type(buffer)=="table" and buffer.size>AC_MAX_SIZE then return end
    textNames = {}
    local uniq = {}
    setLexerSpecificStuff()
    for _, pattern in ipairs(IDENTIFIER_PATTERNS) do
        local startPos = 0
        while true do
            local s, e = editor:findtext(pattern, SCFIND_REGEXP, startPos + 1)
            if not s then
                break
            end
            if not shouldIgnorePos(s) and e - s + 1 >= MIN_IDENTIFIER_LEN then
                local word = editor:textrange(s, e)
                uniq[normalize(word)] = word
            end
            startPos = e
        end
    end
    for _, v in pairs(uniq) do
        table.insert(textNames, v)
    end
    table.sort(
        textNames,
        function(a, b)
            return normalize(a) < normalize(b)
        end
    )
end

function do_autocomplete()
    local pos = editor.CurrentPos
    local startPos = editor:WordStartPosition(pos, true)
    local len = pos - startPos
    if not INCREMENTAL and editor:AutoCActive() then
        return
    end
    if len < MIN_PREFIX_LEN and not editor:AutoCActive() then
        return
    end
    local prefix = normalize(editor:textrange(startPos, pos))

    -- PHP variable support
    if prefix:sub(1, 1) == "$" then
        prefix = prefix:sub(2)
        len = len - 1
    end
    -- ::keyword support
    local match = prefix:match("^:+")
    if match then
        prefix = prefix:sub(#match + 1)
        len = len - #match
    end
    -- keyword.:subkeyword style autocompletion
    local menuItems = {}
    local seen = {}
    local dbgcnt = 1
    for _, name in ipairs(mergedNames) do
        name = name:match("([^(]-%s*)[%(|]") or name:match("(.*)") or name -- no () declarations for autocomplete
        --if name then dbgcnt=dbgcnt+1 end ; if dbgcnt < 10 then print("ac:do_autocomplete> "..name) end
        --if name:find(prefix) and #prefix>5 then print ("ac>do_autocomplete1: "..name) end
        local insertName
        local sepPos = name:find("::", 1, true)
		-- autoc Namespace memberlist
        if prefix:find(":") and normalize(name):find(prefix) then
            --if name:find(prefix) and #prefix>5 then print ("ac>do_autocomplete1: "..name) end
            insertName = name
		-- autoc Namespace or member without namespace given
        elseif sepPos then -- understands parent::child APIentries
            local before = name:sub(1, sepPos - 1)
            local after = name:sub(sepPos + 2)
            --if name:find(prefix) and #prefix>5 then print (name, before, after) end
            if normalize(after):find("^" .. prefix) then --completes when prefix matches after ::
                insertName = after
                if name:find(prefix) and #prefix > 5 then
                    debugPrint("ac>do_autoc matching: " .. name)
                end
			-- autoc functionName
            elseif normalize(before):find("^" .. prefix) then
                insertName = before
            end
        else
            if normalize(name):find("^" .. prefix) then
                insertName = name
            end
        end
        --  if DEBUG_MODE then insertName and m<1 then print("ac:do_autocomplete insertName: "..insertName); m=1 end end

        if insertName then
            local normName = normalize(insertName)
            if not seen[normName] then
                seen[normName] = true
                table.insert(menuItems, insertName)
                if #menuItems >= MENUITEMS_MAX then
                    break
                end
            end
        end
    end

    if next(menuItems) then
        local list = table.concat(menuItems, "\1")
        editor.AutoCIgnoreCase = IGNORE_CASE
        editor.AutoCCaseInsensitiveBehaviour = 1
        editor.AutoCSeparator = 1
        editor.AutoCMaxHeight = 8
        editor:AutoCShow(len, list)
        if normalize(menuItems[1]) == prefix and not calledByHotkey then
            if CASE_CORRECT then
                if CASE_CORRECT_INSTANT or #menuItems == 1 then
                    editor:AutoCShow(len, menuItems[1])
                    editor:AutoCComplete()
                end
                if #menuItems > 1 then
                    editor:AutoCShow(len, list)
                end
            end
            if #menuItems == 1 then
                editor:AutoCCancel()
                return
            end
        end
        lastAutoCItem = #menuItems - 1
        if lastAutoCItem == 0 and calledByHotkey and CHOOSE_SINGLE then
            editor:AutoCComplete()
        end
    else
        if editor:AutoCActive() then
            editor:AutoCCancel()
        end
    end
end

function do_calltip(char)
	 local pos = editor.CurrentPos
	 local strCalltip = ""
	 local entry
	 local dbgcnt=1 --limit candidate list 
	 local tipCount = 0
	 if pos < 1 then return end
	
	 -- Suche das Wort direkt vor der Klammer
	 local startPos = editor:WordStartPosition(pos - 1, true)
	 local funcName = editor:textrange(startPos, pos - 1)
	 if #funcName<MIN_IDENTIFIER_LEN then return end
	 
	 funcName = funcName:gsub("^::?", "") or funcName -- ::keyword support
	 debugPrint("ac>calltip searchString "..funcName) 
	 if not funcName or #funcName == 0 then return end
		
	for _, entry in ipairs(mergedNames) do
	  local fullLine = entry
	  local extractedName
	
	--if  entry:find("BookmarkDelete")then print ("candidate "..entry) end 	
   --[[ 
		if dbgcnt<=5 then print(entry) end	
		if  entry:find(funcName) and entry:find(funcName) then 
		dbgcnt=dbgcnt+1
		if dbgcnt< 5 then 
			print("ac>calltip candidates: "..(entry)) 
			local tmp= entry:match("::([%w_]+)%(") or ""
		end
		if tmp then print("could match with: "..fullLine ) end
	  end
]]	  
	  local prefixMatch =fullLine:match("^(.-)%(")
	--	 for Namespace::members scite not autocomlete will show the Calltip

	  if prefixMatch == funcName then -- gfuncName(h at the very start (i.e. no namespace)
		 extractedName = prefixMatch
	  else
		 extractedName = entry:match("::([%w_]+)%(") -- ::Member(c)h
	  end
	  
		-- now check whether what we extracted is our target function
		if extractedName == funcName then
		  -- Argumentliste innerhalb der Klammern extrahieren
		  local args = fullLine:match("%((.-)%)") or ""
		  if args ~= "" then 			 
			 if tipCount == 0 or not strCalltip:find(args, 1, true) then --dedupe
				tipCount = tipCount + 1
				if tipCount == 1 then
				  strCalltip = args
				else
				  strCalltip = strCalltip .. "\n" .. args
				end
				print(fullLine)
			 end
		  end
		end
		dbgcnt=0
	  end  -- Ende der for-Schleife

	  -- Calltip nur anzeigen, wenn wir etwas gesammelt haben
	  if tipCount > 0 then
		 editor:CallTipShow(pos, strCalltip)
	  end
	  strCalltip=""

end

local function handleChar(char, calledByHotkey)
    if props["Language"] == "" or (buffer.size and buffer.size > AC_MAX_SIZE) then
        return
    end
    if editor.Lexer == 1 then
        return
    end

	local startChars=props["calltip."..editor.LexerLanguage..".parameters.start"]
	if not startChars then startChars="(" end
	local found = false

	for i = 1, #startChars do
		 if startChars:sub(i, i) == char then
			  found = true
			  break
		 end
	end
 
    if found then
        do_calltip(char)
    else
        do_autocomplete()
    end
end

local function handleKey(key, shift, ctrl, alt)
-- todo Tab autocomplete
    -- starte ac bei ctre-space
    if props["Language"] == "" or (buffer.size and buffer.size > AC_MAX_SIZE) then
        return
    end
    if key == 0x20 and ctrl and not (shift or alt) then -- ^Space
        handleChar(nil, true)
        return true
    end
    if alt or not editor:AutoCActive() then
        return
    end

    if key == 0x8 then -- VK_BACK
        if not ctrl then
            -- Need to handle it here rather than relying on the default
            -- processing, which would occur after handleChar() returns:
            editor:DeleteBack()
            handleChar()
            return true
        end
    elseif key == 0x25 then -- VK_LEFT
        if not shift then
            if ctrl then
                editor:WordLeft() -- See VK_BACK for comments.
            else
                editor:CharLeft() -- See VK_BACK for comments.
            end
            handleChar()
            return true
        end
    elseif key == 0x26 then -- VK_UP
        if editor.AutoCCurrent == 0 then
            -- User pressed UP when already at the top of the list.
            if WRAP_ARROW_KEYS then
                -- Select the last item.
                editor:AutoCSelect(menuItems[#menuItems])
                return true
            end
            -- Cancel the list and let the caret move up.
            editor:AutoCCancel()
        end
    elseif key == 0x28 then -- VK_DOWN
        if editor.AutoCCurrent == lastAutoCItem then
            -- User pressed DOWN when already at the bottom of the list.
            if WRAP_ARROW_KEYS then
                -- Select the first item.
                editor:AutoCSelect(menuItems[1])
                return true
            end
        -- Cancel the list and let the caret move down.
        --editor:AutoCCancel()
        end
    elseif key == 0x5A and ctrl then -- ^z
        editor:AutoCCancel()
    end
end

--
-- clear buffers cache but keep APINames[lexer]
--
local function clearBufferCache()
		debugPrint("ac>clearBufferCache")
		for k in pairs(mergedNames) do mergedNames[k] = nil end
end

function handleOnWord()
	state = state or {}
	state.textNamesStart = state.textNamesStart or 0
	if not apiLoaded then apiLoaded=0 end
        debugPrint("ac> OnWord inProject "..props["project.inProject"])

	buildNames() --collect TextNames from current Buffer

	if props["project.inProject"]=="1" then
		 -- Merge API and text names
		if not apiCache[editor.LexerLanguage] then loadApiNames() end
			if apiLoaded==0 then
				debugPrint("ac>OnWord,in Project, merging APICache["..editor.LexerLanguage.."]..")
				for _, n in pairs(apiCache[editor.LexerLanguage]) do table.insert(mergedNames, n) end
				for _, n in ipairs(textNames) do table.insert(mergedNames, n) end
				state.textNamesStart = #mergedNames + 1 --store mergedNames current Index for later rewrites.
				apiLoaded=1 --mark Array as clean.
			else
				debugPrint("ac>OnWord, Skip merging APICache["..editor.LexerLanguage.."], already done") 
			-- Delete old textNames, starting from remembered Index
				for i = #mergedNames, state.textNamesStart, -1 do table.remove(mergedNames, i) end

			-- write mergedNames only from Textnames  
				for _, n in ipairs(textNames) do table.insert(mergedNames, n) end
			end
		else
			debugPrint("ac>OnWord, not in Project, merging only buffers textnames")		
		-- write New Textnames to the remembered Index. I added a Lua5.1 compatible version in extman.lua 
			table.move(textNames, 1, #textNames, 1, mergedNames)
		end

		--for _, n in pairs(mergedNames) do  if  n:find("Perform")then print ("found:"..n) end  end
		
	
end


function handleSwitchFile()
    setLexerSpecificStuff()

    if editor.LexerLanguage and not apiCache[editor.LexerLanguage] then
			debugPrint("ac>onWord: resetting BufferCache")
        clearBufferCache()
		  loadApiNames()
	else
		debugPrint("ac>onSwitchFile: reusing cached entries:", countAPICache())
    end
    editor:Colourise(0, editor.Length)
    if props["project.ctags.update"] == "" then
        props["project.ctags.update"] = "1"
    end
    buildNames()

end

function handleOnSave()
    debugPrint("ac>onSave")
    apiLoaded=1    
end

function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

function handleOpen()
    local tmpdir = os.getenv("TMP") or os.getenv("TEMP")
    debugPrint("ac>onOpen")
    
    -- Ensure the document is styled first, so we can filter out
    -- words in comments and strings.
    editor:Colourise(0, editor.Length)

    -- Then load apinames but dont try to read the file while its been written.
    apiLoaded = 0
	 local lockfile = tmpdir .. dirSep .. "project.ctags.lock"
    if editor.LexerLanguage and not apiCache[editor.LexerLanguage] then
        clearBufferCache()
        for i = 1, 4 do
            if not file_exists(lockfile) then
                loadApiNames()
					 break
            else
					sleep(1)
					if i>=4 then 
						debugPrint("Error. Stopped waiting for ctags to be regenerates. Please Try to delete the File manually.")
						debugPrint(lockfile)
					end
            end
            
        end
    end
    handleOnWord()
end

-- Event handlers
scite_OnChar(handleChar)
scite_OnKey(handleKey)
scite_OnWord(handleOnWord)
--scite_OnDwellStart(handleOnWord)
scite_OnSwitchFile(handleSwitchFile)
scite_OnSave(handleOnSave)
scite_OnOpen(handleOpen)
