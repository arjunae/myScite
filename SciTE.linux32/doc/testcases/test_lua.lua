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
local serpent = require("serpent")
--print(serpent.dump(_G)) -- full serialization
--print(serpent.line(_G)) -- single line, no self-ref section
print(serpent.block(_G,{nocode = true,maxlevel=1})) -- multi-line indented, no self-ref section

line=0
marker_define(0,0)

-- test some scite pane api functions
editor:GotoLine(line+10)
editor:MarkerAdd(line,0)
editor:MarkerDelete(line,0)

--print_registryidx()
print ("lua Version",_VERSION)
-- Test Scite->lua global Variable namespace
print("Value of IDM_NEXTMSG", IDM_NEXTMSG)

