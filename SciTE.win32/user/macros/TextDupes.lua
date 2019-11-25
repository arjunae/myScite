--[[
		cleanDupes.lua
		- iterate through and notify about any dupes found within the inital selection.
		- Also Mark dupes found.
		- write collected words to word_arr.
		- now iterate through word_arr. Search for its words above the initial selection.
		- Show a dialog with dupes found / ask to remove them.
		todo: actually remove dupes.
--]]

local inspect= require("inspect")
-- Define a Marker for highlighting Duplicates
local marker_dupesA=20
editor.IndicStyle[marker_dupesA] = INDIC_TT
editor.IndicFore[marker_dupesA] = 0x956585
local onlyPrintDupes=true
-- UserStrips Return Value
local stripText="" 

--
-- convert to str_words from either table format
-- 
function wordsFromTable(tbl,arr)
	local str_tbl=""
	local str_arr=""
	if tbl then
		for index, s_word in pairs(tbl) do 
			str_tbl=str_tbl..s_word["word"].." "
			--print(s_word["word"].." [s:"..s_word["start"].." e:"..s_word["end"].."]")
		end
		return str_tbl
	end	
	if arr then
		local str_arr=table.concat(arr," ")
		return str_arr
	end
end

--
-- Mark dupes
--
function markDupes(dupes_tbl)
	for idx,wordDef in pairs(dupes_tbl) do
		local wStart=wordDef["start"]
		local wLength=tonumber(wordDef["end"])+1-tonumber(wStart)
		if (wStart and wLength) then
			EditorMarkText(wStart, wLength, marker_dupesA) -- common.lua
		end
	end
end

-- todo write a function to clear duplicates of words specified by the first argument
function clearList(dupeLst,pStart,pEnd)

end

--
-- Collect all Words within either a given initial Selection or a range
--
function collectSelWords(pStart,pEnd)
	local words_cnt=0	
	local words_arr={} -- {"word"=nil|count} -- Detect dupes within source Selection
	local dupes_tbl={} -- { [index], {"word","start",end"}}
	local word_start, word_end
	
	if (pStart and pEnd) then editor:SetSel (pStart, pEnd) end
	local sel_text = editor:GetSelText()
	if sel_text == '' then  print("(Error) Please define a selection first"); return end
	local pStart=editor.SelectionStart-1
	local pEnd=editor.SelectionEnd	
	-- Collect words (words_arr) and append their dupe count
	for word in sel_text:gmatch('[%a%d-_]+') do
		words_cnt=words_cnt+1
		if (words_arr[word]==nil) then 
			words_arr[word]=0;
		elseif words_arr[word]>=0 then
			words_arr[word]=words_arr[word]+1
		end
	end
	-- Create dupes_tbl from words_arr
	for word,word_count in pairs(words_arr) do
		if word_count>0 then
			word_start, word_end=string.find(sel_text,word)		
			if (word_start and word_end) then
				dupes_tbl[#dupes_tbl+1]={["word"]=word,["start"]=pStart+word_start,["end"]=pStart+word_end}
			end
		end	
	end
	--  Mark any dupes found within the source Selection
	if #dupes_tbl>0 then
			print ("(Note) Mark "..#dupes_tbl.." Dupes within the source selection:")
			print("> "..wordsFromTable(dupes_tbl))
			markDupes(dupes_tbl)
	end
	if words_cnt> 0 then
		print("(Note) Collected "..words_cnt.." words for dupe search. (Pattern used: [%a%d-_]+)")
		print("(Status) ...Now searching for Dupes above...")	
		findDupesSel(words_arr, 0, editor.SelectionStart)
		return true
	end
	
	return false
end

--
-- search for collected Words above the Selection
-- add their start and endpos to words_tbl
--
function findDupesSel(words_arr, startPos, endPos)
	local dupes_tbl = {} -- { [index], {"word","start",end"}}
	local singles_arr = {}
	-- Create a new Selection
	-- Search from buffers start till the beginning of the initial Selection.
	editor:SetSel (startPos, endPos)
	editor.SearchFlags=SCFIND_WHOLEWORD | SCFIND_MATCHCASE
	for s_word,flag in pairs(words_arr) do
		editor:TargetFromSelection()
		wordStart=editor:SearchInTarget(s_word)
		if wordStart ~=-1  then
			--print("keep: "..s_word)
			wordEnd=editor:WordEndPosition(wordStart)
			dupes_tbl[#dupes_tbl+1]={["word"]=s_word,["start"]=wordStart,["end"]=wordEnd}	
		else
			--print("remove: "..s_word)
			dupes_tbl[#dupes_tbl+1]=nil
			singles_arr[#singles_arr+1]=s_word
		end
	end
	if (#dupes_tbl==0) then 
		print ("(STATUS) No dupes found within Selection")
		return false
	end
	-- Print Dupes and Uniques
	dupeLst=wordsFromTable(dupes_tbl)
	singlesLst=wordsFromTable(nil,singles_arr)
	print("dupes>\n"..dupeLst)
	print("uniques>\n"..singlesLst)
	-- Show strip 
	if (#stripText == 0 and not onlyPrintDupes) then
		scite.StripShow("") -- clear strip
		scite.StripShow("!'Remove Dupes from Selection?'["..dupeLst.."]((OK))(&Cancel)")
	end
	
	return true
end

function OnStrip(control, change)
	--  ask to clear dupes within the selection
	if control == 2 and change == 1 then -- OK clicked
		scite.StripShow("") 
		stripText = scite.StripValue(1)
		clearList(stripText)
		-- editor:SetSel(endPos,endPos) -- DeSelect Range
	end	
	if control == 3 and change == 1 then -- Cancel clicked
		scite.StripShow("") 
	end
end

collectSelWords()
EditorClearMarks(marker_dupesA) -- common.lua	