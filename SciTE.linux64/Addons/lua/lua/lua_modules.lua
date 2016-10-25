
-- make Lua packages available to SciTE from a standard location defined with the 'ext.luamodules.directory' scite property
if props['ext.luamodules.directory'] then
	package.path = package.path..';'..props['ext.luamodules.directory']..[[\lua\?.lua;]]..props['ext.luamodules.directory']..[[\lua?\init.lua]]
	package.cpath = package.cpath..';'..props['ext.luamodules.directory']..[[\c\?.dll]]
end

