--
-- list_defines.lua; probably the very first lua header defines fetcher created in 2018 ;)
-- 01.01.2018 / Thorsten Kani / Marcedo { at } habMalNeFrage. { de}
-- License: BSD three Clause
-- grab all function defines, list their names (with parameters)
-- exclude Constants, exclude _underscoredStuff, exclude multiline stuff. (see code Docs)
--

function list_defines(param)
outline=" "

	-- input section --
	if not param then param="ndis.h" end --testing
	if not param:match(".h") then return end
	if param:match("^_") then return end --c std / mingw internal functions	
	print("["..param.."]")
	for entry in io.lines(param) do
	--  parse section --
		local name=nil rest=nil func1=nil func2=nil multiline=false write=true
		
		name, rest=entry:match("#define ([%w_]+)(%(.*)")  -- funcName, param and rest of line  [#define ble(...) blo(...)]
		if rest then	
			rest=string.gsub(rest," ","") -- Normalises function deco containing spaces.
			param,func2=rest:match("^([%(|%w|%d|%,|%.|%_|]+%))(.*)" ) --  funcNameParam to nothing [#define bly(qwe)]
			if rest:match("%\\") then multiline=true param="multi_line" end
			func1=name..param
		end 
		if not func1 then func1,func2=entry:match("#define ([%w_]+)%s+([a-zA-Z_]+)$") end -- names without parameter [#define bla blubb]
		if not func1 then func1,func2=entry:match("#define ([%w_]+)%s+([a-zA-Z_]+%(.*)") end -- name to function [#define bla __mingwname(...)]
		if not func2 then func2 ="" else 
			if func2:match("%\\") then multiline=true func2="multi_line" func1 = name end -- tag and include names of multiline defines
		end
				
	-- Filter section --
		if func1 then
			if func2 then together= func1..func2 end
			if multiline then write=false end -- strip multiline defines (param has Backslash)
			if func2:match("^[%s_]+")  then write=false end -- strip compiler internals (param is numeric only)
			if together:match("^[%s_]+")  then write=false end --strip compiler internals (func Name begins with underscore)
			if together:match("TEXT") then write=false end  -- strip Text constants (param contains the TEXT Macro)
			if together:match("IID") then write=false end -- strip GUID Constants
			if together:match("GUID_BUILDER") then write=false end
			if func1:match("^[^%l]+$") then write=false end -- strip all Uppercases constants
			--if func1:match("^[^%l]+%(") then write=false end -- strip all Uppercases functions
			if together:match("MINGW") then write=true end 
			if  write then outline=outline.."{"..func1.."}{"..func2.."}".."\n" end
		end
	end
	
print(outline)
--outFile=io.open("outFile","a+")
--if outline then outFile:write(outline) end
--io.close(outFile)
end

list_defines(arg[1])
