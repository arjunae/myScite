

--You can use this to mark all occurrences of a word in the document. You should add something like this in your SciTEUser.properties:

--command.name.37.*=markOccurrences
--command.mode.37.*=subsystem:lua,savebefore:no
--command.37.*=markOccurrences
--command.shortcut.37.*=Ctrl+.

--command.name.38.*=clearOccurrences
--command.mode.38.*=subsystem:lua,savebefore:no
--command.38.*=clearOccurrences
--command.shortcut.38.*=Ctrl+,

--And this functions in your SciTEStartup.lua:

function clearOccurrences()
    scite.SendEditor(SCI_SETINDICATORCURRENT, 0)
    scite.SendEditor(SCI_INDICATORCLEARRANGE, 0, editor.Length)
end

function markOccurrences()
    if editor.SelectionStart == editor.SelectionEnd then
        return
    end
    clearOccurrences()
    scite.SendEditor(SCI_INDICSETSTYLE, 0, INDIC_ROUNDBOX)
    scite.SendEditor(SCI_INDICSETFORE, 0, 255)
    local txt = GetCurrentWord()
    local flags = SCFIND_WHOLEWORD
    local s,e = editor:findtext(txt,flags,0)
    while s do
        scite.SendEditor(SCI_INDICATORFILLRANGE, s, e - s)
        s,e = editor:findtext(txt,flags,e+1)
    end
end

function isWordChar(char)
    local strChar = string.char(char)
    local beginIndex = string.find(strChar, '%w')
    if beginIndex ~= nil then
        return true
    end
    if strChar == '_' or strChar == '$' then
        return true
    end
    
    return false
end

function GetCurrentWord()
    local beginPos = editor.CurrentPos
    local endPos = beginPos
    if editor.SelectionStart ~= editor.SelectionEnd then
        return editor:GetSelText()
    end
    while isWordChar(editor.CharAt[beginPos-1]) do
        beginPos = beginPos - 1
    end
    while isWordChar(editor.CharAt[endPos]) do
        endPos = endPos + 1
    end
    return editor:textrange(beginPos,endPos)
end

--Agustín Fernández, August 22, 2007

--I have added a test for no selection at the top of markOccurrences - to stop Scite (ver 3.5.2) crashing if there is no selection in the editor.

--Gavin Holt, Dec 20, 2014 