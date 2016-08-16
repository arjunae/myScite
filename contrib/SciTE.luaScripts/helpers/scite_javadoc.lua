
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
--                                                                            --
-- Greetings, SciTE-user.                                                     --
-- This script is a little helper to create and maintain javadoc-style        --
-- comments. It works like the commenter in Eclipse; i.e.                     --
-- If you put                                                                 --
-- /**|                                                                       --
-- and press Enter (the | indicates where the cursor is located), you get     --
-- /**                                                                        --
--  * |                                                                       --
--  */                                                                        --
--                                                                            --
-- When pressing Enter in the situation                                       --
--     /**                                                                    --
--      * One Bourbon, One Scotch, One Beer|                                  --
--      */                                                                    --
-- you get                                                                    --
--     /**                                                                    --
--      * One Bourbon, One Scotch, One Beer                                   --
--      * |                                                                   --
--      */                                                                    --
--                                                                            --
-- There is also a setting javadoc_find_params, which will find parameters    --
-- for a function; e.g.                                                       --
-- /**|                                                                       --
-- bool born(int under, char *a="a bad", array sign) {                        --
-- }                                                                          --
-- will evaluate to                                                           --
-- /**                                                                        --
--  *                                                                         --
--  * @param under                                                            --
--  * @param *a (default: "a bad")                                            --
--  * @param sign                                                             --
--  * @return                                                                 --
--  */                                                                        --
-- bool born(int under, char *a="a bad", array sign) {                        --
-- }                                                                          --
-- It check for an opening bracket, and then considers every text between     --
-- commas as a parameter; if there is a space, then the first word is         --
-- considered the type.                                                       --
--                                                                            --
-- for any comments, suggestions or bugs etc, feel free to mail me at         --
-- jerous (a.t.) gmail.com                                                    --
--                                                                            --
-- I hope it is usefull for you,                                              --
-- jerous.                                                                    --
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--


--~ determines if the script should try to find parameters, and add them to
--~ the comment. It will only look for them, if you put the cursor on 1 line
--~ before the function declaration.
javadoc_find_params = true

--~ create and maintain javadoc comments
--~ note: won't work correctly if the comment starts at the first line
--~ so just move it to the second line, and everything is ok!
function OnChar(c)
	expand = "/**"
	if c~="\n" then
		return false
	end
	
	-- are we creating a new comment?
	if editor:textrange(editor.CurrentPos-string.len(expand)-1, editor.CurrentPos-1)==expand then
		-- check here first if we create
		-- if modify, then skip over to the next if where we continue a comment
		-- we suppose if the next line starts with "*" it is a valid comment
		next_line = editor:GetLine(editor:LineFromPosition(editor.CurrentPos)+1)
		if next_line==nil or string.find(next_line, "^%s*%*")==nil then		
			prev_line = editor:GetLine(editor:LineFromPosition(editor.CurrentPos)-1)
			t1,t2,indent = string.find(prev_line, "^(%s*)")
			
			insert = indent.." * \n"
			inserted = false
			
			if next_line ~= nil and javadoc_find_params==true then
				-- here we try to retrieve the function's parameters!
				balance=0
				pos=editor:PositionFromLine(editor:LineFromPosition(editor.CurrentPos)+1)
				
				-- see if there is a "(" on the following line; if not, then
				-- we just create an empty comment
				while char_at(pos)~="(" and char_at(pos)~="\n" and pos<editor.Length do
					pos = pos+1
				end
				
				if char_at(pos)=="(" then
					param = ""
					pos = pos+1
					
					while (char_at(pos)~=")" or balance~=0) and pos<editor.Length do
						if char_at(pos)=="," and balance==0 then
							insert = insert..process_param(param, indent)
							param = ""
							pos=pos+1
							-- skip whitespaces after ","
							while char_at(pos)==" " do
								pos=pos+1
							end 
						end
						if char_at(pos)=="(" then
							balance = balance+1
						end
						if char_at(pos)==")" then
							balance = balance-1
						end
						param = param..char_at(pos)
						pos=pos+1
					end
					
					insert=insert..process_param(param, indent)..indent.." * @return \n"..indent.." */"
					inserted=true
				end
			end
	
			if javadoc_find_params==false or inserted==false then
				insert = insert..indent.." */"
			end
			
			editor:insert(-1, insert)
			-- position at the end of the line
			editor:GotoPos(editor.LineEndPosition[editor:LineFromPosition(editor.CurrentPos)])
			return
		end
	end
	
	-- are we continuing a comment?
	i = editor:LineFromPosition(editor.CurrentPos)-1
	while i>0 do
		line = editor:GetLine(i)
		i = i-1
		
		if string.find(line, "^%s*%*/") then
			break
		end
		
		if string.find(line, "^(%s*)/%*%*")~=nil then
			-- now we're sure we're processing a javadoc comment!
			-- so insert a new line!
		
			prev_line = editor:GetLine(editor:LineFromPosition(editor.CurrentPos)-1)
			t1,t2,indent = string.find(prev_line, "^(%s*)%*")
			if indent==nil then
				t1,t2,indent=string.find(prev_line, "^(%s*)")
				indent = indent .. " "
			end
			editor:insert(-1, indent.."* ")
			
			-- position at the end of the line
			editor:GotoPos(editor.LineEndPosition[editor:LineFromPosition(editor.CurrentPos)])
			break
		end

		if string.find(line, "^%s*%*")==nil then
			-- we're not inside a comment
			-- abort the mission
			break
		end
	end
end


function process_param(param, indent)
	if param=="" then
		return ""
	end
	default=""
	insert=""
	-- if there is a space, we suppose the first word is the type
	-- so we omit that!
	t1,t2,t3,param=string.find(param, "^([a-zA-Z_0-9&\*]* )(.*)$")
	
	-- check if there is a default, indicated by "param=value"
	if string.find(param, "=",0,true)~=nil then
		t1,t2,param,default=string.find(param, "^(.-)=(.*)$")
	end
	
	insert = insert..indent.." * @param "..param
	if default~="" then
		insert = insert .. " (default: "..default..")"
	end
	insert = insert.."\n"
	
	return insert
end

-- returns the character at position p as a string
function char_at(p)
	return string.char(editor.CharAt[p])
end

