
-- Complicated script to toggle binary value
-- The simple script has a flaw, when a toggle-word is followed by one or more whitespaces. e.g. "if (false)" will -- toggle, while "if ( false )" won't. Here is a more complicated version that is more robust. Both functions are --needed, link to scite_ToggleBoolean() in your SciTE Options file.

-- general lua function to alternatingly replace a bool-ish word in a string
function ToggleBoolean(str)
-- create a 2 colum table with toggle expressions
	local TogglePairTable = {}	
	TogglePairTable["FALSE"] = "TRUE"
	TogglePairTable["false"] = "true"
	TogglePairTable["False"] = "True"
	TogglePairTable["YES"] = "NO"
	TogglePairTable["yes"] = "no"
	TogglePairTable["0"] = "1"

-- replace left column string in table with righ column string
	for findString,replaceString in pairs(TogglePairTable) do
		if string.find(str, findString) then return string.gsub(str, findString, replaceString) end
	end
	
-- replace right column string in table with left column string	
	for replaceString,findString in pairs(TogglePairTable) do
		if string.find(str, findString) then return string.gsub(str, findString, replaceString) end
	end
	
	return str
end

-- For use in SciTE
-- this selects the the word under the caret
-- side effect: discards existing selection
function scite_ToggleBoolean()
	--save position
	local StartPos = editor.CurrentPos

	editor:WordRight()
	editor:WordLeftExtend() 
	local sel = editor:GetSelText()
	editor:ReplaceSel(ToggleBoolean(sel))
	
	-- reset position
	editor:SetSel(StartPos, StartPos) 
end

--SK

--Script for increment and decrement number
--This script increment and decrement the next number found in text.

    function NumPlusPlus()
     output:ClearAll()
     local StartPos = editor.CurrentPos
     local CurLine = editor:LineFromPosition(StartPos)
     
     local fs,fe = editor:findtext("\-*[0-9]+", SCFIND_REGEXP,StartPos)
     editor:SetSel(fs,fe)
     local Number = editor:GetSelText()
     
     editor:ReplaceSel(Number + 1)
     editor:GotoPos(fs)
    end

    function NumMinusMinus()
     output:ClearAll()
     local StartPos = editor.CurrentPos
     local CurLine = editor:LineFromPosition(StartPos)
     
     local fs,fe = editor:findtext("\-*[0-9]+", SCFIND_REGEXP,StartPos)
     editor:SetSel(fs,fe)
     local Number = editor:GetSelText()
     
     editor:ReplaceSel(Number - 1)
     editor:GotoPos(fe)
    end

--DaveMDS

--Script for transposing two characters
--This script flips the positions of two adjacent characters.

    function transpose_characters()
      local pos = editor.CurrentPos
      editor:GotoPos(pos-1)
      editor.Anchor = pos+1
      local sel = editor:GetSelText()
      editor:ReplaceSel(string.sub(sel, 2, 2)..string.sub(sel, 1, 1))
      editor:GotoPos(pos)
    end

--Myles Strous--

--Insert the current date at the cursor position
--I missed this feature in SciTE. Add the following lines into User Options File (SciTEUser.properties)

    command.name.12.*=InsertDate
    command.12.*=InsertDate
    command.subsystem.12.*=3
    command.mode.12.*=savebefore:no
    command.shortcut.12.*=Ctrl+d

--Add the following lines into Lua Startup Script:

    function InsertDate()
       editor:AddText(os.date("%Y-%m-%d"))
    end

--Klaus Hummel--

--This version replaces the current selection, if there is one:

-- replace current selection with text
-- if there is none, insert at cursor position
function replaceOrInsert(text)
    local sel = editor:GetSelText()
    if string.len(sel) ~= 0 then
        editor:ReplaceSel(text)
    else
        editor:AddText(text)
    end
end

-- insert the current date in YYYY-mm-dd format
function insertDate()
    replaceOrInsert(os.date("%Y-%m-%d"))
end

--And another function for inserting the current time:

-- insert the current time in HH:MM:SS Timezone format
function insertTime()
    replaceOrInsert(os.date("%H:%M:%S %Z"))
end

--Chris Arndt--

--INSERT automatic current date time in mode .LOG (similar notepad)

--Add the following lines into User Options File (SciTEUser.properties)

    command.name.12.*=InsertDateTimeLog
    command.12.*=InsertDateTimeLog
    command.subsystem.12.*=3
    command.mode.12.*=savebefore:no
    command.shortcut.12.*=Enter

--Add the following lines into Lua Startup Script:

    function InsertDateTimeLog()
       local Linea1, esLog, esLogMayus
       Linea1 = editor:GetLine(0)
       if Linea1 == nil then Linea1 = "0000" end
       esLog = string.sub(Linea1,1,4)
       esLogMayus = string.upper (esLog)
       if esLogMayus == ".LOG" then
          editor:AddText("\n\n--------------------\n")
          editor:AddText(os.date("%d.%b.%Y__%Hh:%Mm"))
          editor:AddText("\n--------------------\n")
       else editor:AddText("\n")
       end
    end

--Barquero--

--Lua calculator/expression evaluator
--A simple Lua expression evaluator for calculating stuff. Highlight a valid Lua expression and run the script to perform the calculation or evaluation.

function SciTECalculator()
  local expr = editor:GetSelText()
  if not expr or expr == "" then return end
  local f, msg = loadstring("return "..expr)
  if not f then
    print(">Calculator: cannot evaluate selection") return
  end
  editor:ReplaceSel(tostring(f()))
end

--khman--

--Find selection

local findText = editor:GetSelText()
local flag = 0

output:ClearAll()

if string.len(findText) > 0 then
	trace('>find: '..findText..'\n')
	local s,e = editor:findtext(findText,flag,0)
	local m = editor:LineFromPosition(s) - 1
	local count = 0

	while s do
		local l = editor:LineFromPosition(s)

		if l ~= m then
			count = count + 1

			local str = string.gsub(' '..editor:GetLine(l),'%s+',' ')

			local add = ':'..(l + 1)..':'
			local i = 8 - string.len(add)
			local ind = ' '
			while (string.len(ind) < i) do
				ind = ind..' '
			end

			trace(add..ind..str..'\n')
			m = l
		end

		s,e = editor:findtext(findText,flag,e+1)
	end

	trace('>result: '..count..'\n')
else
	trace('! Select symbol and replay')
end

--gans_A--

--Text Cleaner
--A simple script that gets rid of annoying unrecognized tab(\t) and newline(\r\n) characters in pasted text.

function cleanText(reportNoMatch)
    editor:BeginUndoAction()
        for ln = 0, editor.LineCount - 1 do
            local lbeg = editor:PositionFromLine(ln)
            local lend = editor.LineEndPosition[ln]
            local text = editor:textrange(lbeg, lend)
            
            text = string.gsub(text, "\\t", "\t")
            text = string.gsub(text, "\\r", "\r")
            text = string.gsub(text, "\\n", "\n")
            
            editor.TargetStart = lbeg
            editor.TargetEnd = lend
            editor:ReplaceTarget(text)
        end--for
    editor:EndUndoAction()
end

--sirol81--

--Swap Comma
--Transpose positions when separated, of words by commas.. If " when separated, of words" is selected in the previous sentence and swapped, it would now read, "Transpose positions of words, when separated by commas." It also works with semicolons.

function swap_comma()
    local str = editor:GetSelText()
    local b = string.gsub(str,".*[,;]","")
    local c = string.gsub(str,".*([,;]).*","%1")
    local a = string.gsub(str,c..".*","")
    editor:ReplaceSel(b..c..a)
end

--hellork-- 