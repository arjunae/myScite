require 'lfs'
require 'io'

-- Global container that holds all snippet definitions.
_G.snippets = {}

-- Available SciTE env variables that will be expanded
--FilePath	full path of the current file
--FileDir	directory of the current file without a trailing slash
--FileName	base name of the current file
--FileExt	extension of the current file
--FileNameExt	$(FileName).$(FileExt)
--Language	name of the lexer used for the current file
--SessionPath	full path of the current session
--CurrentSelection	value of the currently selected text
--CurrentWord	value of word which the caret is within or near
--Replacements	number of replacements made by last Replace command
--SelectionStartColumn	column where selection starts
--SelectionStartLine	line where selection starts
--SelectionEndColumn	column where selection ends
--SelectionEndLine	line where selection ends
--CurrentMessage	most recently selected output pane message
--SciteDefaultHome	directory in which the Global Options file is found
--SciteUserHome	directory in which the User Options file is found
--SciteDirectoryHome	directory in which the Directory Options file is found
--APIPath	list of full paths of API files from api.filepattern
--AbbrevPath	full path of abbreviations file
--ScaleFactor	the screen's scaling factor with a default value of 100

-- load snippets from snippets folder
--local dir = props['SciteDefaultHome'].."\\snippets"
--local files = fxlib.readDir(dir..'\\*.txt')

--for i,f in ipairs(files) do 
--	_G.snippets[string.sub(f,1,-5)] = fxlib.readFile(dir..'\\'..f)
--end

for fn in lfs.dir(props['SciteDefaultHome'].."\\user\\snippets") do 
	if fn ~= "." and fn ~= ".." then		
		local f = io.open(props['SciteDefaultHome'].."\\user\\snippets\\"..fn, 'rb')
		_G.snippets[fn:sub(1, -5)] = f:read('*a')
		f:close()
	end
end

function onSnippetSelected(name)
	insertSnippet(name)
end

-- Inserts a snippet
function insertSnippet(name)
  s_text = _G.snippets[name]
  if s_text then

    -- Expand SciTE variables
    s_text = s_text:gsub( '%$%((.-)%)', function(prop) return props[prop] end )
    -- s_text = unescape(s_text)

    editor:ReplaceSel(s_text)
    --editor:NewLine()
  end
end

-- Begins expansion of a snippet
-- Based on SELECTED word
--function insertSnippetBySelection()
--  insertSnippet(editor:GetSelText())
--end

-- Begins expansion of a snippet
-- Based on word BEFORE cursor
function onInsertSnippetByWord()
  local pos = editor.CurrentPos
  local p2 = editor:WordEndPosition(pos,true)
  local p1 = editor:WordStartPosition(pos,true)
  local word = editor:textrange(p1,p2)
  local s_text = _G.snippets[word]

  if s_text then

    -- Replace SciTE variables.
    s_text = s_text:gsub( '%$%((.-)%)', function(prop) return props[prop] end )
    -- s_text = unescape(s_text)

    editor:DeleteRange(p1, p2-p1)
    editor:InsertText(p1, s_text)
    --editor:NewLine()
  end
end

-- Lists available snippet triggers as an autocompletion list.
function onShowSnippets()
  local list, list_str = {}, ''
  for s_name in pairs(_G.snippets) do table.insert(list, s_name) end
  table.sort(list)  
  scite_UserListShow(list, 1, onSnippetSelected)
end

scite_Command {
  'Snippets|onShowSnippets|F9'
}

--scite_Command {
--  'Word to Snippet|onInsertSnippetByWord|F10'
--}