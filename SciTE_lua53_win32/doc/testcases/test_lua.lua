-- go@ dofile $(FilePath) 
-- ^^tell Scite to use its internal Lua interpreter.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function marker_define(idx,typ)
-- Test scite object namespace
	editor:MarkerDefine(idx,typ)
end

function print_registryidx()
-- Print scites registryindex namespace
	for k, v in pairs( debug.getregistry () ) do
		print(k, v)
	end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~

line=0
marker_define(0,0)

-- test some scite pane api functions
editor:GotoLine(line+10)
editor:MarkerAdd(line,0)
editor:MarkerDelete(line,0)

--print_registryidx()
print (_VERSION)
-- Test Scite->lua global Variable namespace
print(IDM_NEXTMSG)
