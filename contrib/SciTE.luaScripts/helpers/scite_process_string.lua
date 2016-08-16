
-- This script incrementally finds a C string (style 6 per C/C++ property file) and optionally adds wrapper characters around the string so that locale translation can be utilized.

--Here is a version that performs the operation in two phases. In phase one, the script looks for a string. In --phase two, the script performs the operation on the string. The user can then choose not to perform the --phase two operation on a particular string by moving the caret after a string is found in phase one. This --enables the operation to be selectively performed. With some practice, this can be done quickly.

function SciteProcessString()
  local StringStyle = 6         -- constant: language style for strings
  local function StyleAt(pos) return math.mod(editor.StyleAt[pos], 128) end
  local function StrStart(pos)
    local sprev, style = StyleAt(pos-1), StyleAt(pos)
    if sprev ~= StringStyle and style == StringStyle then return true end
  end
  local i = editor.CurrentPos
  if StrStart(i) then
    local inserted = false
    ------------------------------------------------------------
    -- insert _( if not present
    ------------------------------------------------------------
    editor:GotoPos(i)
    if i >= 2 and editor:textrange(i-2, i) ~= "_(" then
      editor:BeginUndoAction()
      inserted = true
      editor:AddText("_(")
      i = i + 2
    end
    while i < editor.Length and StyleAt(i) == StringStyle do i = i + 1 end
    ------------------------------------------------------------
    -- insert ) if _( inserted
    ------------------------------------------------------------
    editor:GotoPos(i)
    if inserted then
      editor:AddText(")")
      editor:EndUndoAction()
    end
  else
    while i < editor.Length do
      if StrStart(i) then editor:GotoPos(i) break end
      i = i + 1
    end
  end
end
