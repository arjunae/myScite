
-- opens URL via selection or by checking text under cursor
-- Kein-Hong Man <khman@users.sf.net> Public Domain 2008
-- * execute call is non-Win32! tested on Ubuntu 6.10
-- * URL delimited by ", ' or whitespace
-- * does nothing about text encoding!
function open_url()
  local string = string
  local function charat(s, p) return string.sub(s, p, p) end
  local function delim(c) return string.match(c, "[\"'%s]") end
  -- if there is a selection, use exactly, else analyze
  local txt = editor:GetSelText()
  if #txt == 0 then
    -- get details of current line, position
    local p1 = editor.CurrentPos
    local ln = editor:LineFromPosition(p1)
    txt = editor:GetLine(ln)
    if not txt then return end
    local p2 = editor:PositionFromLine(ln)
    p1 = p1 - p2 + 1; p2 = p1
    -- extend text segment to left
    while p1 > 1 do
      if delim(charat(txt, p1 - 1)) then break end
      p1 = p1 - 1
    end
    -- extend text segment to right
    while p2 <= #txt do
      if delim(charat(txt, p2)) then break end
      p2 = p2 + 1
    end
    -- exit if nothing matched
    if p1 == p2 then return end
    txt = string.sub(txt, p1, p2 - 1)
  else
    -- trim extraneous whitespace
    txt = string.gsub(txt, "^%s*(.-)%s*$", "%1")
    -- fail on embedded whitespace
    if string.match(txt, "%s") then return end
  end
  if string.match(txt, "^http://.+") or
     string.match(txt, "^ftp://.+") or
     string.match(txt, "^www%..+") then
    --print("URL='"..txt.."'") --DEBUG
    os.execute("x-www-browser "..txt.." &")
  end
end