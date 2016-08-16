 leave column highlighting as a trivial exercise.

function marker_define(idx,typ,fore,back)
	editor:MarkerDefine(idx,typ)
	if fore then editor:MarkerSetFore(idx,color_parse(fore)) end
	if back then editor:MarkerSetBack(idx,color_parse(back)) end
end

-- Compatibility: Lua-5.1
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

--~ Naming this function OnOpen causes it to run every time SciTE opens a file
--~ and determine if the opened file has :somenumber: in the extension.
--~ If it does, we open it in another window and go to that line.
function OnOpen()
    local ext = props['FileExt']   -- e.g 'cpp'
	if string.match(ext,':') then
		marker_define(0,0,'black','red')
		local extSplit = split(ext,':')
		local f = props['FileName']    -- e.g 'test'
		local path = props['FileDir']  -- e.g. '/home/steve/progs'
--~ 		print (f,ext,extSplit[1],extSplit[2],path)
		newpat=path..'/'..f..'.'..extSplit[1]
		scite.Open(newpat)
		line=tonumber(extSplit[2]-1)
		editor:GotoLine(line)
		editor:MarkerAdd(line,0)
		editor.SelectionStart   = editor.CurrentPos
		editor.SelectionEnd   = editor.LineEndPosition[line]
	end
end

