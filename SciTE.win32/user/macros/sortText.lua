--go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--[[--------------------------------------------------
SortText.lua
Authors: Tugarinov Sergey, mozers™, Tymur Gubayev
version 2.1.1
------------------------------------------------------
Sorting selected lines_tbl alphabetically and vice versa
Connection:
	Set in a file .properties:
		command.name.37.*=Sorting of lines A… z / z… A
		command.37.*=dofile SortText.lua
		command.mode.37.*=subsystem:lua,savebefore:no
--]]--------------------------------------------------

local lines_tbl = {} 
local sort_direction_decreasing = false 
local patt = [[^[%s'"`«]*]] 

local function CompareTwoLines(line1, line2)
	line1 = line1:gsub(patt, '')
	line2 = line2:gsub(patt, '')
	if sort_direction_decreasing then
		return (line1:lower() > line2:lower())
	else
		return (line1:lower() < line2:lower())
	end
end

local function GetSortDirection()
	local end_line = lines_tbl[#lines_tbl]:gsub(patt, '')
	for i = 1, #lines_tbl-1 do
		local comp_line = lines_tbl[i]:gsub(patt, '')
		if comp_line ~= end_line then
			return CompareTwoLines(comp_line, end_line)
		end
	end
end

local sel_text = editor:GetSelText()
local sel_start = editor.SelectionStart
local sel_end = editor.SelectionEnd
if sel_text ~= '' then
	for current_line in sel_text:gmatch('[^\n]+') do
		lines_tbl[#lines_tbl+1] = current_line
	end
	if #lines_tbl > 1 then
		sort_direction_decreasing = GetSortDirection()
		table.sort(lines_tbl, CompareTwoLines)
		local out_text = table.concat(lines_tbl, '\n')..'\n'
		editor:ReplaceSel(out_text)
	end
end

editor:SetSel(sel_start, sel_end)