
-- This installs LuaInspect in SciTE
local LUAINSPECT_PATH = props['ext.luainspect.directory']
package.path = package.path .. ";" .. LUAINSPECT_PATH .. "/metalualib/?.lua"
package.path = package.path .. ";" .. LUAINSPECT_PATH .. "/luainspectlib/?.lua"
--require "luainspect.scite":install()

