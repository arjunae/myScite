
--Expands words such as "if" and "for" to a correctly indented clause as you type. I find this very useful since it saves me from typing the parentheses and braces, and then taking time to format them correctly.

--Try if | and for |

--Expansion only occurs when the open file has a c or header file extension. The script also recognizes when you are typing in a commented section and will not auto-expand.

    local in_word,current_word, substituting
    local find = string.find   


    -- Expand "if " to
    -- if () {
    --     
    -- }
    -- And set the cursor between the ()
    -- Also works for "while "
    function expandIf()
    	-- The text is "if "
    	editor:AddText("(")
    	-- "if ("
    	-- Remember where to bring the cursor to
    	local tmp = editor.CurrentPos
    	editor:AddText(") {")
    	local line = editor:LineFromPosition(editor.CurrentPos)
    	local tmpi = editor.LineIndentation[line]

    	editor:AddText("\n")
    	while tmpi >= 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("\n")
    	tmpi = editor.LineIndentation[line]
    	while tmpi > 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("}")
    	
    	-- Bring the cursor into the "()"
    	editor:GotoPos(tmp)
    end


    function expandElse()
    	local line = editor:LineFromPosition(editor.CurrentPos)
    	local tmpi = editor.LineIndentation[line]

    	editor:AddText("{\n")
    	while tmpi >= 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	local tmp = editor.CurrentPos
    	editor:AddText("\n")
    	tmpi = editor.LineIndentation[line]
    	while tmpi > 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("}")
    	editor:GotoPos(tmp)
    end


    function expandFor()
    	local line = editor:LineFromPosition(editor.CurrentPos)
    	local tmpi = editor.LineIndentation[line]

    	editor:AddText("(")
    	local tmp = editor.CurrentPos
    	editor:AddText("; ; ) {\n")
    	while tmpi >= 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("\n")
    	tmpi = editor.LineIndentation[line]
    	while tmpi > 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("}")
    	editor:GotoPos(tmp)
    end


    function expandDo()
    	local line = editor:LineFromPosition(editor.CurrentPos)
    	local tmpi = editor.LineIndentation[line]

    	editor:AddText("{\n")
    	while tmpi >= 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("\n")
    	tmpi = editor.LineIndentation[line]
    	while tmpi > 0 do
    		editor:AddText("\t")
    		tmpi = tmpi - 4
    	end
    	editor:AddText("} while (")
    	local tmp = editor.CurrentPos
    	editor:AddText(");")
    	editor:GotoPos(tmp)
    end

    function expandCout()
    	editor:AddText(" << \"")
    	local tmp = editor.CurrentPos
    	editor:AddText("\" << endl;")
    	editor:GotoPos(tmp)
    end

    function OnChar(c)
    	if not substituting then
    		return false
    	end
    	
    	-- Only activate on the space character
    	if c == ' ' then
    		-- The currentPos is the character after the cursor
    		-- Get the style of the word that was just typed
    		-- That is, the style of the character before the space
    		cstyle = editor.StyleAt[editor.CurrentPos-2]
    		
    		-- If the typed word is a part of code
    		-- Rather than a part of comments
    		if cstyle == 0 or cstyle == 32 or cstyle == 4 or cstyle == 5 or cstyle == 10 or cstyle == 11 or cstyle == 16 then
    			
    			-- Get the word that was just typed
    				local p, original_pos
    				local lineStart
    				
    				-- get the current position and the start of the current line
    				lineStart = editor:PositionFromLine(editor:LineFromPosition(editor.CurrentPos))
    				original_pos = editor.CurrentPos
    				
    				-- Find the beginning of the current word
    				p = editor.CurrentPos-2
    				-- Stop on the space/tab/newline character
    				while (p >= lineStart) and (find(string.char(editor.CharAt[p]), '%w')) do
    					p = p - 1
    				end
    				-- Increment 1 to get the first character of the current word
    				p = p + 1
    				
    				-- Select the word and get it
    				editor:SetSel(p, editor.CurrentPos-1)
    				current_word = editor:GetSelText()
    				-- Clear the selection
    				editor:SetSel(original_pos, original_pos)
    			
    			-- Got the word, now expand
    				if current_word == "elseif" then
    					editor:GotoPos(editor.CurrentPos - 3)
    					editor:AddText(" ")
    					editor:GotoPos(editor.CurrentPos + 3)
    					expandIf()
    				-- if and while have the same expansion
    				elseif current_word == "if" or current_word == "while"  then
    					expandIf()
    				elseif current_word == "else" then
    					expandElse()
    				elseif current_word == "for" then
    					expandFor()
    				elseif current_word == "do" then
    					expandDo()
    				elseif current_word == "cout" then
    					expandCout()
    				end
    			-- Expansion complete
    		end
    	end


    	-- don't interfere with usual processing!
    	return false
    end  



    function OnOpen(f)
    	local ext = props['FileExt']
    	if ext == 'h' or ext == 'c' or ext == 'hpp' or ext == 'cpp' or ext == 'cxx' or ext == 'cs' then 
    		substituting = true
    	else
    		substituting = false
    	end
    end

    function OnSwitchFile(f)
    	local ext = props['FileExt']
    	if ext == 'h' or ext == 'c' or ext == 'hpp' or ext == 'cpp' or ext == 'cxx' or ext == 'cs' then 
    		substituting = true
    	else
    		substituting = false
    	end
    end

--Originally based off of SteveDonovan's code for word substitution. 
