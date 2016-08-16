

--The script collects the functions and display in the usertable. It works with php file. There is no oop-design. I hope having time to develop this script.

----------------------------------------------
-- @ script  : SciTE_DisplayFunctions.lua
-- @ creator : gongadze
-- @ desc    : the script collects the functions and display in the usertable
-- @ desc    : if you stand on a functionname and press Ctrl-2 you are 
-- @ desc    : immediately routed to the function definition
-- @ version : v0.02 
----------------------------------------------
function UserListShow(list)

   local s = ''
   local sep = ';'
   local n = table.getn(list)
   for i = 1,n-1 do
      s = s..list[i]..sep
   end
   s = s..list[n]
   editor.AutoCSeparator = string.byte(sep)
   editor:UserListShow(12,s)
   editor.AutoCSeparator = string.byte(' ')
 end
function AllLinesWithText(txt,flags)

    if not flags then flags = 0 end
    local s,e = editor:findtext(txt,flags,0)
    local result = {}
    while s do 
      local l = editor:LineFromPosition(s)
      -- trace(l..' '..editor:GetLine(l))
      func = strip(editor:GetLine(l))
      table.insert(result,func)
      s,e = editor:findtext(txt,flags,e+1)
    end    
    return result
end
function strip(str)

	str=string.gsub(str, "^%s+","")
	if string.find(str, "\r\n") then
	return string.gsub(str, "\r\n", "")
	else
	return string.gsub(str, "\n", "")
	end
end
function charAt(n)

	return string.char(editor.CharAt[n])
end
function getCurrentWord()
		
	_curpos = editor.CurrentPos
	regexp = "[a-zA-Z_]" --> ProgLang-specific REGEXP
	curpos = _curpos
	char=charAt(curpos)
	right=''
	while string.find(char,regexp)  do
		right=right..char
		curpos = curpos + 1
		char=charAt(curpos)
		--trace(char)
	end
	regexp = "[a-zA-Z_]"
	curpos = _curpos-1
	char=charAt(curpos)
	left=''
	while string.find(char,regexp) do
		left=char..left
		curpos = curpos - 1
		char=charAt(curpos)
	end
	result = left..right
	if result == '' then
		return false
	else
		return result
	end
end
function isInFunctionTable(table,value)

	indicator = false
	for k,v in table do
		if string.find(v,("^function "..value)) then indicator = true end
	end
	return indicator
end
function DisplayFunctions()

	function_catch = '^[ |\t]*function [a-zA-Z0-9_:&]*([a-zA-Z0-9,_ \$\=\&]*)' -->  ProgLang-specific REGEXP
	ki = AllLinesWithText(function_catch,SCFIND_REGEXP)
	current_word = getCurrentWord()
	if  (current_word) and (isInFunctionTable(ki,current_word)) then
		local s,e = editor:findtext("^[ |\t]*function "..current_word,SCFIND_REGEXP,0)
		editor:GotoPos(s)
		-- editor:MarkerAdd(editor:LineFromPosition(editor.CurrentPos),1)
	else
		if ( table.getn(ki) > 0 ) then
			UserListShow(ki)
		end
	end
	return 0
end
function OnUserListSelection(listID, s)

  local s,e = editor:findtext(s,SCFIND_REGEXP,0)
  editor:GotoPos(s)
  return 0
end

