--[[
		cleanDupes.lua
		- iterate through and notify about any dupes found within the inital selection.
		- write collected words to word_arr.
		- iterate through word_arr and search for dupes found above the initial selection.
		- Show a dialog with dupes found / ask to remove them / todo: optionally remove them
--]]


local inspect= require("inspect")
local stripText="" -- User choosen Dupes edited in a UserStrip

--
-- Collect all Words within the initial Selection
--
function collectSelWords()
	local sel_text = editor:GetSelText()
	local sel_start = editor.SelectionStart
	local sel_end = editor.SelectionEnd
	local words_arr= {} -- {"word"=nil|count} -- Detect dupes within source Selection
	local dupe_lst="" -- collected dupes for printOut
	local words_cnt=0
	local dupe_cnt=0
	if sel_text == '' then  print("(Error) Please define a selection first"); return end
	
	-- Collect words, filter dupes
	for word in sel_text:gmatch('[%a%d-_]+') do
		words_cnt=words_cnt+1
		if (words_arr[word]==nil) then 
			words_arr[word]=0;
		elseif words_arr[word]>=0 then
			dupe_lst=dupe_lst..word.." "
			dupe_cnt=dupe_cnt+1
			words_arr[word]=words_arr[word]+1
		end
	end

	if words_cnt> 0 then
		print("(Note) Collected ".. words_cnt.." words for dupe search. (Pattern used: [%a%d-_]+)")
		if dupe_cnt>0 then
			print ("(Note) Skipping "..dupe_cnt.." Dupes within the source selection:")
			print (">\t"..dupe_lst)
		end
		print("(Status) ...Searching for Dupes...")	
		findDupesSel(words_arr, 0, sel_start)
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
	
	dupeLst,singlesLst=printDupes(dupes_tbl,singles_arr)
	if  (#stripText == 0 ) then
		scite.StripShow("") -- clear strip
		scite.StripShow("!'Remove Dupes from Selection?'["..dupeLst.."]((OK))(&Cancel)")
	end
	return true
	
end

--
-- Print all dupes (start >-1)
-- 
function printDupes(words_tbl,singles_arr)
	local dupes=""
	for index, s_word in pairs(words_tbl) do 
		dupes=dupes..s_word["word"].." "
		--print(s_word["word"].." [s:"..s_word["start"].." e:"..s_word["end"].."]")
	end
	local singles=table.concat(singles_arr," ")
	
	print ("(Status) Words found in Selection:\n>\t"..dupes.."\t")
	print ("(Status) Words _not_ found in Selection:\n>\t"..singles.."\t")
			
	return dupes, singles
end

-- todo write a function to clear dupes
collectSelWords()


-- Arjunea
function OnStrip(control, change)
	--  ask to clear dupes within the selection
	if control == 2 and change == 1 then -- OK clicked
		scite.StripShow("") 
		stripText = scite.StripValue(1)
		-- editor:SetSel(endPos,endPos) -- DeSelect Range
	end	
	if control == 3 and change == 1 then -- Cancel clicked
		scite.StripShow("") 
	end
end