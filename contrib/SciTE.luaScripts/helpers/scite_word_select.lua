-- This script allows you to select the word under the cursor. This is similar to the Edit/Select Word command in many text editors.

--First of all, put the following code into your Lua startup file:

function isWordChar(char)
    local strChar = string.char(char)
    local beginIndex = string.find(strChar, '%w')
    if beginIndex ~= nil then
        return true
    end
    if strChar == '_' then
        return true
    end
    return false
end

function SelectWord()
    local beginPos = editor.CurrentPos
    local endPos = beginPos
    while isWordChar(editor.CharAt[beginPos-1]) do
        beginPos = beginPos - 1
    end
    while isWordChar(editor.CharAt[endPos]) do
        endPos = endPos + 1
    end
    if beginPos ~= endPos then
        editor.SelectionStart = beginPos
        editor.SelectionEnd   = endPos
    end
end

After that, you need to bind a shortcut key for SelectWord. In your properties file place the following code, replacing 13 with an unused command number. Also, feel free to use whatever shortcut you like instead of Ctrl+J.

command.name.13.*=Select Word
command.mode.13.*=subsystem:lua,savebefore:no,groupundo
command.shortcut.13.*=Ctrl+J
command.13.*=SelectWord

--Explanations

--The algorithm is quite simple. We have two variables which will be the the start and the end positions of the word. Initially, they are equals and point to cursor's position. We move beginPos to the left (by decrementing it) and endPos to the right (by incrementing it) until we hit the word's boundaries. Then we set the editor's selection using these variables.

--MocanuCristian 