-- promptNew.lua - a simple lua prompt in SciTEs output pane.
-- Note for scripts using OnKey/OnChar : ignore events from the outputpane with if output.focus.
-- based on original prompt.lua
-- enhanced and adapted for Lua 5.3, 05.25 ThorstenKani arjunae@nurfuerspam.de
-- run with dofile("promptNew.lua") as last command in your scitestartup.lua file
--
-- commands:
-- <expr>			evaluate as lua. (access to global vars only)
-- run <file>	runs file
-- /pp <table>	pretty prints table
-- /sh <cmd>		run cmd in shell
-- quit			ends session
-- help			prints above
--

local env = setmetatable({}, { __index = _G })

local prompt = '> '
local prompt_len = #prompt
print 'Scite-Lua ❤'

trace(prompt)

-- returns if a given fileNamePath exists
local function file_exists(name)
	local f = io.open(name, "r")
	if f then f:close() return true end
	return false
end

-- rename custom loader to avoid clobbering built-in load
local function load_file(path)
	if not path then path = props['FilePath'] end
	if not file_exists(path) then
		return false, "lua file not found: " .. path
	end
	dofile(path)
	return true
end

local sub = string.sub

local function strip_prompt(line)
	if sub(line,1,prompt_len) == prompt then
		return sub(line, prompt_len+1)
	end
	return line
end

-- efficient join for pretty_print
local function join(tbl, delim)
	local res = {}
	for i,v in ipairs(tbl) do res[#res+1] = tostring(v) end
	return table.concat(res, delim)
end

function pretty_print(...)
	local args = {...}
	for _, val in ipairs(args) do
		if type(val) == 'table' then
			print('{' .. join(val, ', ') .. '}')
		elseif type(val) == 'string' then
			print('"' .. val .. '"')
		else
			print(val)
		end
	end
end


local function run_shell_command(command)
	local f = io.popen(command, 'r')
	if f then
		local output = f:read('*all')
		f:close()
		return output
	else
		return "Error: Could not execute command."
	end
		return true
end

scite_OnOutputLine(function(line)
	line = strip_prompt(line)
	--  Wenn der User "quit" eintippt, Handler abmelden
	if line:match('^quit%s*$') then
	print("REPL beendet.")
	scite_OnOutputLine(nil,true,true)
	return true
	end

	--  Display help
	if line:match('^help%s*$') then
	print("Available commands:")
	print("<expr>			evaluate Lua expression (globals only)")
	print("run <file>		run a Lua file")
	print("/pp <table>	pretty-print a table or value")
	print("/sh <cmd>		run cmd in shell")
	print("quit				exit the REPL session")
	print("help				show this help message")
	end

	-- Starte Shell
	if sub(line,1,3) == '/sh' then  
		local sh_command = line:match('^/sh%s*(.*)')
		if sh_command then
			local output = run_shell_command(sh_command)
			trace(output)
			trace(prompt)
		end
		return true
	end
	
	--  strip local from 'local foo = expr'
	local var, expr = line:match('^%s*local%s+([_%a][_%w]*)%s*=%s*(.+)$')
	if var then
	line = var .. ' = ' .. expr
	end

	--  handle pretty-print shortcut
	if sub(line,1,3) == '/pp' then
	line = 'pretty_print(' .. sub(line,4) .. ')'
	end

	--  Starte lua script
	if sub(line,1,3)=='run' and (sub(line,4,4)==' ' or #line==3) then
	local filename = line:match('^run%s*(.*)')
	local ok, err = load_file(filename)
	if not ok then print(err) end

	elseif sub(line, 1,1)~='/' then
	-- eval in persistenter Umgebung
	local chunk, err = load('return ' .. line, 'chunk', 't', env)
	if not chunk then
		chunk, err = load(line, 'chunk', 't', env)
	end
	if not chunk then
		print(err)
	else
		local ok, result = pcall(chunk)
		if not ok then
		print(result)
		elseif result ~= nil then
		print('result=', result)
		end
	end
	end


	trace(prompt)
	return true
end)
