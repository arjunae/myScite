-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Test Scite->lua global Variable namespace
print(IDM_NEXTMSG)

-- Test scite object namespace
function marker_define(idx,typ)
	editor:MarkerDefine(idx,typ)
end

line=0
marker_define(0,0)
editor:GotoLine(line+1)
editor:MarkerAdd(line,0)
--editor:MarkerDelete(line,0)