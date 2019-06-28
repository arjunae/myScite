-- go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.

--[[
	Debugging lua Scripts ran within Scites Lua Subsystem required a second instance and a helper script like RemDebug.
	The attached "Solution" uses a lua clib called dbghelper to debug scite lua scripts using the same Scite instance.
	Status:  Test prototype using debugger.lua from S.Lembcke 
	Needs: A debuggee named dbge.lua
	
	Reference:	
		http://tset.de/dbghelper/index.html 
		https://github.com/slembcke/debugger.lua
]]

package.path = package.path .. ";../?.lua"
require "dbghelper"
local coPrompt="coDebug> "
local status, info

--Debuggee
local cr = coroutine.create(loadfile("dbge.lua"))
status="up"

-- Create a table of all the locally accessible variables.
-- Globals are not included when running the locals command, but are when running the print command.
local function local_bindings(cr,offset, include_globals)
	local level = 0
	local func = debug.getinfo(cr,level).func
	local bindings = {}
	
	-- Retrieve the upvalues
	do local i = 1; while true do
		local name, value = debug.getupvalue(func, i)
		if not name then break end
		bindings[name] = value
		i = i + 1
	end end
	
	-- Retrieve the locals (overwriting any upvalues)
	do local i = 1; while true do
		local name, value = debug.getlocal(cr,level, i)
		--print(name,value)
		if not name then break end
		bindings[name] = value
		i = i + 1
	end end
	
	-- Retrieve the varargs (works in Lua 5.2 and LuaJIT)
	local varargs = {}
	do local i = 1; while true do
		local name, value = debug.getlocal(cr,level, -i)
		if not name then break end
		print (varargs[i], value)
		varargs[i] = value
		i = i + 1
	end end
	if #varargs > 0 then bindings["..."] = varargs end
	
	if include_globals then
		-- In Lua 5.2, you have to get the environment table from the function's locals.
		local env = (_VERSION <= "Lua 5.1" and getfenv(func) or bindings._ENV)
		return setmetatable(bindings, {__index = env or _G})
	else
		return bindings
	end
end


local function pretty(obj, max_depth)
	if max_depth == nil then max_depth = 4 end
	
	-- Returns true if a table has a __tostring metamethod.
	local function coerceable(tbl)
		local meta = getmetatable(tbl)
		return (meta and meta.__tostring)
	end
	
	local function recurse(obj, depth)
		if type(obj) == "string" then
			-- Dump the string so that escape sequences are printed.
			return string.format("%q", obj)
		elseif type(obj) == "table" and depth < max_depth and not coerceable(obj) then
			local str = "{"
			
			for k, v in pairs(obj) do
				local pair = pretty(k, 0).." = "..recurse(v, depth + 1)
				str = str..(str == "{" and pair or ", "..pair)
			end
			
			return str.."}"
		else
			-- tostring() can fail if there is an error in a __tostring metamethod.
			local success, value = pcall(function() return tostring(obj) end)
			return (success and value or "<!!error in __tostring metamethod!!>")
		end
	end
	
	return recurse(obj, 0)
end

local function cmd_locals(cr)
	local bindings = local_bindings(cr,1, false)
	
	-- Get all the variable binding names and sort them
	local keys = {}
	for k, _ in pairs(bindings) do table.insert(keys, k) end
	table.sort(keys)
	
	for _, k in ipairs(keys) do
		local v = bindings[k]
		
		-- Skip the debugger object itself, "(*internal)" values, and Lua 5.2's _ENV object.
		if not rawequal(v, dbg) and k ~= "_ENV" and not k:match("%(.*%)") then
			trace(k.." => "..pretty(v).."\n")
		end
	end
	
	return false
end

local SOURCE_CACHE = {["<unknown filename>"] = {}}
local function where(info, context_lines)
	local key = info.source or "<unknown filename>"
	local source = SOURCE_CACHE[key]

	if not source then
		source = {}
		local filename = info.source:match("@(.*)")
		print (filename)
		if filename then
			for line in io.lines(filename) do table.insert(source, line) end 
		else
			for line in info.source:gmatch("(.-)\n") do table.insert(source, line) end
		end
		
		SOURCE_CACHE[key] = source
	end
	
	if info.currentline < 1 then info.currentline =  info.linedefined end
	if source[info.currentline] then
		for i = info.currentline - context_lines, info.currentline + context_lines do
			local caret = (i == info.currentline and " => " or "    ")
			local line = source[i]
			if line then trace(i.." "..caret.." "..line.."\n") end
		end
	else
		trace("Error: Source file '%s' not found.\n", info.source);
	end
	
	return false
end

local function cmd_where(cr,context_lines)
	if not info then return end
	return (info and where(debug.getinfo(cr,0,"nlS"), tonumber(context_lines) or 5))
end

local function format_stack_frame_info(info)
	if not info then return end
	local path = info.source:sub(2)
	local fname = (info.name or string.format("<%s:%d>", path, info.linedefined))	
	return string.format("%s:%d in '%s'", path, info.currentline, fname)
end


local function cmd_trace(cr)
	local location = format_stack_frame_info(info)
	local str=debug.traceback(cr) or ""
	
	if location and str then
		print(location)
		print(str)
	end
	return false
end


function eval_lua(line)
    local f,err = loadstring(line,'local')
    if not f then 
      print(err)
    else
      local ok,res = pcall(f)
      if ok then
         if res then print('result= '..res) end
      else
			print(res)
			cr_step(cr,"crl") 
      end      
    end
end

local function writehelp()
	print("(w) where\n(t)\n(l) locals\n(t)trace\n(s) step\n(.) eval as lua\n(q) quit")
end

local function cmd_go()
	--tbd
end

local function attach()
	status="up"
	--tdb
end

local function cmd_clear()
	status="clear"
	--tbd
	status="up"
	return true
end

local function cr_step(cr,mask,count,dest)
local ok, what, x = debug.resumeuntil(cr, mask)
			info=debug.getinfo(cr, 0, "lnS") or {}
			--print(ok,what,x)
		return ok
end

local function cmd_handler(cr,cmd,param)	
local ok
	if status=="down" and not cmd:match("^[Ahq%.].*$") then return -2 end
	
	if cmd then 
		if cmd=='t' then cmd_trace(cr) end
		if cmd=='w' then cmd_where(cr,5) end
		if cmd=='l' then cmd_locals(cr) end
		if cmd=='q' then ok=-1 end
		if cmd=='.' then eval_lua(param) end
		if cmd=='h' then writehelp() end
		if cmd=='A' then attach(param) end
		
		if cmd=='s' then 	
			ok=cr_step(cr,"crl")
		end	
	end
	return ok
end

local function onOutputAppend(str,strb)
	local ok
	if type(strb)=="string" then str=strb end
	str=string.sub(str,#coPrompt+1)

	local cmd, param=str:match("^([Atwlsq%.h])(.*)$")	
	if cmd then
		ok=cmd_handler(cr,cmd,param)
	elseif not string.match(str,"error") then
		print("#dbg Unknown Command: "..str)
	end
	
	if (ok==-1) then
		print("#dbg Quit")
		scite_OnOutputLine(onOutputAppend,true)
		return
	elseif(ok==-2) then
		print("#dbg Please (A)ttach to a debuggee or (q)uit debugger")
	elseif(ok==false) then
		print("#dbg Returned from Debuggee.")
		ok=cmd_clear()
		status="down"
	elseif (ok==true) then
		print("\n#dbg "..format_stack_frame_info(info))
	end
	
	trace(coPrompt)	
	return(true)
end

scite_OnOutputLine (onOutputAppend,line)
trace(coPrompt)

ok= cr_step(cr, "crl" )
