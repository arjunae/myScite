
--Recursively folds or unfolds a file. Normally, a click at a fold doesn't recursively fold and unfold. A Ctrl-click at a fold does recursively fold and unfold. However, if you want to limit the folding depth, you will need the following Lua script as a substitute.

-- toggle folds, with customizable fold range
-- khman 20060117, public domain

function FoldSome()
  local FOLDSTART = 1024        -- level to start folding (from 1024)
  local FOLDDEPTH = 3           -- fold depth; comment out if no limit
  --------------------------------------------------------------------
  local FOLDEND = FOLDSTART + (FOLDDEPTH or 9999)
  if FOLDEND <= FOLDSTART or FOLDEND > 4096 then FOLDEND = 4096 end
  local start, ending, hide
  editor:Colourise(0, -1)       -- update doc's folding info
  for ln = 0, editor.LineCount - 1 do
    local foldRaw = editor.FoldLevel[ln]
    local foldLvl = math.mod(foldRaw, 4096)
    local foldHdr = math.mod(math.floor(foldRaw / 8192), 2) == 1
    -- fold if within limits and is a fold header
    if foldHdr and foldLvl >= FOLDSTART and foldLvl < FOLDEND then
      local expanded = editor.FoldExpanded[ln]
      if foldLvl == FOLDSTART and not start then -- start fold block
        -- fix a hide/show setting for whole doc, for consistency
        if hide == nil then hide = expanded end
        start = ln + 1 -- remember range
        ending = editor:GetLastChild(ln, foldLvl)
      end
      editor.FoldExpanded[ln] = not hide
    end
    -- if end of block, perform hide or show operation
    if start and ln == ending then
      if hide then
        editor:HideLines(start, ending)
      else
        editor:ShowLines(start, ending)
      end
      start, ending = nil, nil
    end
  end--for
end
