
--local inspect= require("inspect")

--
-- Collect all Words within the Selection
--
function collectSelWords()
	local words_tbl = {} 
	local sel_text = editor:GetSelText()
	local sel_start = editor.SelectionStart
	local sel_end = editor.SelectionEnd

	if sel_text ~= '' then
		for word in sel_text:gmatch('%a+') do
			words_tbl[#words_tbl+1]= {["word"]=word,["start"]=-1,["end"]=-1}
		end
		if #words_tbl > 0 then findDupes(words_tbl, sel_start) end
	end
end

--
-- search for collected Words above the Selection
-- add their start and endpos to words_tbl
--
function findDupes(words_tbl, endPos)
		-- Create a new Selection and search within
		editor:SetSel (0,endPos)
		editor:TargetFromSelection()
		editor.SearchFlags=SCFIND_WHOLEWORD | SCFIND_MATCHCASE
		for index, s_word in ipairs(words_tbl) do 
			wordStart=editor:SearchInTarget(s_word["word"])
			if wordStart ~=-1  then
				wordEnd=editor:WordEndPosition(wordStart)
				words_tbl[index]={["word"]=s_word["word"],["start"]=wordStart,["end"]=wordEnd}	
			else
				table.remove(words_tbl,index)
			end
		end
	-- DeSelect Range
	-- editor:SetSel(endPos,endPos) 
	printDupes(words_tbl)
end

--
-- Print all dupes (start >-1)
-- 
function printDupes(words_tbl)
	local dupesMsg="Dupes found:\n"
	--print(inspect(words_tbl))
	for index, s_word in ipairs(words_tbl) do 
		dupesMsg=dupesMsg..s_word["word"].." "
			--print("[s:"..s_word["start"].." e:"..s_word["end"].."]")
	end
	print (dupesMsg)	
end

-- todo write a function showing a user strip with all dupes in
-- then ask to clear them within the selection
collectSelWords()
