
--This script enables Visual Studio-like XML autocompletion: ending tags are automatically added and --attributes are automatically quoted. This works for XHTML and any XML files.

--Copy the following code in your Lua startup script:

function OnChar(c)
	local nLexer = editor.Lexer
	if nLexer ~= 4 and nLexer ~= 5 then return false end

	-- tag completion
	if c == ">" then
		local pEnd = editor.CurrentPos - 1
		if pEnd < 1 then return false end
		local nStyle = editor.StyleAt[pEnd - 1]
		if nStyle > 8 then return false end
		local nLastChar = editor.CharAt[pEnd - 1]
		if nStyle == 6 and nLastChar ~= 34 then return false end
		if nStyle == 7 and nLastChar ~= 39 then return false end
		if nLastChar == 47 or nLastChar == 37 or nLastChar == 60 or nLastChar == 63 then return false end
		local pStart = pEnd
		repeat
			pStart = pStart - 1
			if (editor.CharAt[pStart] == 32) then
				pEnd = pStart
			end
		until editor.CharAt[pStart] == 60 or pStart == 0
		if editor.CharAt[pStart + 1] == 47 then return false end
		if pStart == 0 and editor.CharAt[pStart] ~= 60 then return false end
		local tag = editor:textrange(pStart + 1, pEnd)
		editor:InsertText(editor.CurrentPos, "</" .. tag .. ">")
	end

	-- attribute quotes
	if c == "=" then
		local nStyle = editor.StyleAt[editor.CurrentPos - 2]
		if nStyle == 3 or nStyle == 4 then
			editor:InsertText(editor.CurrentPos, "\"\"")
			editor:GotoPos(editor.CurrentPos + 1)
		end
	end

	return false
end

Bugs
Please report bugs here

RomainVallet

Dreamweaver style xml / html autocomplete

(bugfix posted: 3 July 2008)

Similar to the above (can only use one or the other) but auto closes tags in Dreamweaver style. Each time you type '</' in an XML or HTML file it looks for the corresponding opening tag and auto finishes it for you.

e.g. You type

<html><body>test</

and autocomplete finishes the tag as

<html><body>test</body>


--------------------------------------------------------------------
-- XML Autocompletion Dreamweaver Style
-- Author: Paul Healsey (www.phdesign.com.au)
-- Version: 1.2 
--------------------------------------------------------------------

function AutocompleteXmlDW(c)
	local nLexer = editor.Lexer
	if nLexer ~= 4 and nLexer ~= 5 then return false end
	
	-- tag completion
	if c == "<" then
		xmlComplete = true
	elseif xmlComplete == true and c == "/" then
		--find last opening tag
		--local xmlPattern = "<([^%s]-)([^>]-)>"
		local closedTags = {}
		ctr = 0
		local tag = FindXmlTag(editor.CurrentPos, closedTags)
		if tag ~= nil then
			editor:InsertText(editor.CurrentPos, tag .. ">")
			editor:GotoPos(editor.CurrentPos + string.len(tag) + 1)
		end
		xmlComplete = false
	else
		xmlComplete = false
	end

	return false
end

function FindXmlTag(pos, closedTags)
	local tag = nil
	local startPos, endPos
	
	endPos = FindCharReverse(">", pos)
	if endPos == -1 then return nil end
	startPos = FindCharReverse("<", endPos)
	if startPos == -1 then return nil end
	pos = startPos
	-- get tag name (first word inside <>)
	tag = editor:textrange(startPos + 1, endPos)
	_, _, tag = string.find(tag, "/*([^%s]*)")
	--print("tag = '"..tag.."'")
	if CharAt(pos + 1) == "?" then
		-- this tag doesn't need to be closed (e.g. <?xml?>
		tag = FindXmlTag(pos, closedTags)
	elseif CharAt(endPos - 1) == "/" then
		-- this tag closes itself (e.g. <tag />)
		tag = FindXmlTag(pos, closedTags)
	elseif CharAt(pos + 1) == "/" then
		table.insert(closedTags, tag)
		--for i,v in ipairs(closedTags) do print(i,v) end
		--print("---------------")
		tag = FindXmlTag(pos, closedTags)
	elseif RemoveItemReverse(closedTags, tag) == true then
		--for i,v in ipairs(closedTags) do print(i,v) end
		--print("---------------")
		tag = FindXmlTag(pos, closedTags)
	elseif table.getn(closedTags) > 0 then
		tag = FindXmlTag(pos, closedTags)
	end 
	
	return tag
end

function RemoveItemReverse(tbl, str)
	for i = table.getn(tbl), 0, -1 do 
		if tbl[i] == str then
			table.remove(tbl, i)
			return true
		end
	end
	
	return false
end

function FindCharReverse(char, pos)
	local first = true
	
	while pos > 0 do
		if first then 
			first = false
		else
			pos = pos - 1 
		end
		if CharAt(pos) == char then return pos end
	end
	
	return -1
end

function CharAt(n)
	return string.char(editor.CharAt[n])
end

