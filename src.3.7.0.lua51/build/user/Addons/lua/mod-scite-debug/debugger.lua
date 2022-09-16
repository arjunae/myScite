-- A simple gdb interface for SciTE
-- Steve Donovan, 2007
-- changes: 
-- (1) debug.backtrace.depth will configure depth of stack frame dump (default is 20)
-- (3) first generalized version

if lfs==nil then err,lfs = pcall( require,"lfs")  end --chdir
scite_require 'marker_indic.lua'

local GTK = scite_GetProp('PLAT_GTK')
local stripText = ''

function do_set_menu()
end

--Fixme calling scite_command from within events.

scite_Command {
 -- 'Run|do_run|*{savebefore:yes}|Alt+R',
 -- 'Breakpoint|do_breakpoint|F9'
}

scite_Command {
--	  'Step|do_step|Alt+C',
--	  'Step Over|do_next|Alt+N',
--	  'Go To|do_temp_breakpoint|Alt+G',  
--	  'Kill|do_kill|Alt+K',
--	  'Inspect|do_inspect|Alt+I',
--	  'Locals|do_locals|Alt+Ctrl+L',
--     'Watch|do_watch|Alt+W',
--	  'Backtrace|do_backtrace|Alt+Ctrl+B',
--      'Step Out|do_finish|Alt+M',
--	  'Up|do_up|Alt+U',
--	  'Down|do_down|Alt+D',
}

local lua_prompt = '(lua)'
local prompt
local prompt_len
local sub = string.sub
local find = string.find
local len = string.len
local gsub = string.gsub
local status = 'idle'
local last_command
local last_breakpoint
local traced
local dbg
local catdbg

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local GTK = scite_GetProp('PLAT_GTK')
local dirSep,dirsep

if GTK then
	dirSep = '/'
	dirsep = '/'
else
	dirSep = '\\'
	dirsep='\\'
end

local function at (s,i)
    return s:sub(i,i)
end

function slashify(s)
	return s:gsub('\\','\\\\')
end

--- note: for finding the last occurance of a character, it's actualy
--- easier to do it in an explicit loop rather than use patterns.
--- (These are not time-critcal functions)
function split_last (s,ch)
    local i = #s
    while i > 0 do
        if at(s,i) == ch then
            return s:sub(i+1),i
        end
        i = i - 1
    end
end

function choose(cond,x,y)
	if cond then return x else return y end
end


function join(path,part1,part2)
	local res = path..dirsep..part1
    if part2 then return res..dirsep..part2 else return res end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


function dbg_last_command()
    return dbg.last_command
end

function dbg_status()
    return status
end

function dbg_obj()
	return dbg
end

----- debugger/Lua prompt --------------
-- pretty_print() will try to expand tables, rather like Python will, but with a limit
-- obviously table.concat is much more efficient, but requires that the table values
-- be strings.
local pretty_print_limit = tonumber(scite_GetProp('pretty.print.limit',20))

local function join(tbl,delim,limit)
    local n = table.getn(tbl)
    local res = ''
    local k = 0
    -- this is a hack to work out if a table is 'list-like' or 'map-like'
    local index1 = n > 0 and tbl[1]
    local index2 = n > 1 and tbl[2]
    if index1 and index2 then
        for i,v in ipairs(tbl) do
            res = res..delim..tostring(v)
            k = k + 1
            if k > limit then
                res = res.." ... "
            end
        end
    else
        for i,v in pairs(tbl) do
            res = res..delim..tostring(i)..'='..tostring(v)
            k = k + 1
            if k > limit then
                res = res.." ... "
            end            
        end
    end
    return string.sub(res,2)
end

function pretty_print(...)
    for i,val in ipairs(arg) do
        if type(val) == 'table' then
            if val.__tostring then
                print(val)
            else
                print('{'..join(val,',',pretty_print_limit)..'}')
            end
        elseif type(val) == 'string' then
                print("'"..val.."'")
            else
                print(val)
            end
    end
end

local function strip_prompt(line)
   local prompt_bit = sub(line,1,prompt_len)
   if prompt_bit == prompt or prompt_bit == lua_prompt then
        line = sub(line,prompt_len+1)
    end	
	return line
end

function edit(f)
    scite.Open(f)
end


function cd(path) 
	if lfs then
		lfs.chdir(path)
	else
		os.chdir(path)
	end
end


function eval_lua(line)
    if sub(line,1,1) == '=' then
        line = 'pretty_print('..sub(line,2)..')'
    end    	
    local f,err = loadstring(line,'local')
    if not f then 
      print(err)
    else
      local ok,res = pcall(f)
      if ok then
         if res then print('result= '..res) end
      else
         print(res)
      end      
    end
end

local function set_prompt(p)
    prompt = p..' '
    prompt_len = len(prompt)
end

-- *doc* Either we are running, or not. If running, commands are passed directly
-- to the debugger through the spawner; otherwise we look for property
-- initializations $var = val ($var= will clear the property) or property
-- vars $var; if none of these, then evaluate as a Lua expression, like
-- the canonical Lua prompt (= <expr> prints out a value; otherwise any
-- Lua statement)

function handleDebugPrompt(line)
	local line = strip_prompt(line)
	local state = dbg_status()
	local dbg = dbg_obj()    
    if state ~= 'idle' then        
        dbg.last_command = '<inter>'
        spawner_command(line)
        set_prompt(dbg.prompt)
    else
		local _,prop,val
		_,_,prop,val = find(line,'^%$([^=%s]+)%s*=%s*(.*)')
		if _ then
			props[prop] = val
		else
			_,_,prop = find(line,'^%$(.+)')
			if _ then
				print(prop..' = "'..props[prop]..'"')
			elseif line:sub(1,1) == '>' then
				local r = spawner.popen(line:sub(2))
				trace(r:read('*a'))
				r:close()
			elseif (promptHelp==nil) then
					trace("\t=Debug Prompt=\n\tType in a lua statement\n\tor evaluate Properties by\n\ttyping the $varname / set $varname = val\n")
					promptHelp=false;
					set_prompt(lua_prompt)
			else
				eval_lua(line)
			end
		end
		set_prompt(lua_prompt)
    end
    trace(prompt)
    return true
end

local debug_status = scite_GetProp('debug.status',false)

-- *doc* you can add $(status.msg) to your statusbar.text.1 property if
-- you want to see debugger status.
-- (see SciTEGlobal.properties for examples)
function set_status(s)
    if s ~= status then
        if debug_status then print('setting status to '..s) end
        status = s
        props['status.msg'] = s
        scite.UpdateStatusBar(true)
    end
end

function dbg_status()
    return status
end

------- Generic debugger interface, based on GDB ------
Dbg = class()

function Dbg:init(root)
end

function Dbg:default_target()
    local ext = self.no_target_ext
    if ext then
		-- Ndless SDK: don't use a relative path. Use any ELF file.
      --  local res = props['FileDir']..'\\' --scite_webdev
         local res = props['FileName'] -- Arjunae
		  if ext ~= '' then res = res..'.'..ext end
        return res
    else
        return props['FileNameExt']
    end
end

function Dbg:step()
	dbg_command('step')
end

function Dbg:step_over()
	dbg_command('next')
end

function Dbg:continue()
	dbg_command('cont')
end

function Dbg:quit()
	spawner_command('quit')
    if not self.no_quit_confirm then
        spawner_command('y')
    end
end

function Dbg:set_breakpoint(file,lno)
  dbg_command('break',file..':'..lno)
end

-- generally there are two ways to clear breakpoints in debuggers;
-- either by number or by explicit file:line.
function Dbg:clear_breakpoint(file,line,num)
	if file then
--~ 		dbg_command('delete '..num)
        dbg_command('clear',file..':'..line)
	else
		print ('no breakpoint at '..file..':'..line)
	end
end

-- run until the indicated file:line is reached
function Dbg:gotoL(file,lno)
	dbg_command('tbreak',file..':'..lno)
	dbg_command('continue')
end

function Dbg:set_display_handler(fun)
	-- 0.8 change: if a handler is already been set, don't try to set a new one!
	if self.result_handler then return end
	self.result_handler = fun
end

function Dbg:inspect(word)
	dbg_command('print',word)
end

local skip_file_pattern
local do_skip_includes

--- *doc* you can choose a directory pattern for files which you don't want to skip through
--- for Unix, this is usually easy, but for mingw you have to supply the path to
--- your gcc directory.
function Dbg:auto_skip_over_file(file)
    if not do_skip_includes then return end
    return find(file,skip_file_pattern)
end

function Dbg:finish()
    dbg_command('finish')
end

function Dbg:locals()
	dbg_command('info locals')
end

function Dbg:watch(word)
	dbg_command('display',word)
end

function Dbg:up()
	dbg_command('up')
end

function Dbg:down()
	dbg_command('down')
end

function Dbg:backtrace(depth)
	dbg_command('backtrace',depth)
end

function Dbg:frame(f)
	dbg_command('frame',f)
end

function Dbg:detect_frame(line)
	local _,_,frame = find(line,'#(%d+)')
	if _ then
		dbg:frame(frame)			
	end
end

function Dbg:special_debugger_setup(out)
end

function Dbg:breakpoint_confirmation(line)
	-- breakpoint defintion confirmation
	-- ISSUE: only picking up for breakpoints added _during_ session!
    local _,_,bnum = find(line,"Breakpoint (%d+) at")
	if  _ then
		if last_breakpoint then
			print('breakpoint:',last_breakpoint.line,bnum)
			last_breakpoint.num = bnum
		end		
	end
end

function quote(s)
    return '"'..s..'"'
end

function Dbg:find_execution_break(line)
    local _,_,file,lineno = find(line,self.break_line)
    if _ then return file,lineno end
end

function Dbg:check_breakpoint (b)
    return true
end

-- add our currently defined breakpoints
function Dbg:dump_breakpoints(out)
	for b in Breakpoints() do
        if self:check_breakpoint(b) then
            local f = basename(b.file)
            print (b.file,f)
            out:write('break '..f..':'..b.line..'\n')
        end
	end
end

function Dbg:run_program(out,parms)
	-- Ndless SDK: 'continue' instead of 'run'
	--out:write('c '..parms..'\n')
	out:write('run '..parms..'\n')
end

function Dbg:detect_program_crash(line)
	return false
end

----- Debugger commands --------
local spawner_obj

function do_step()
	if status=="active" then dbg:step() end
end

-- Arjunea
function OnStrip(control, change)
	if control == 2 and change == 1 then -- OK clicked
		scite.StripShow("") 
		stripText = scite.StripValue(1)
		props['debug.target'] = stripText
		do_run()
	end	
	if control == 3 and change == 1 then -- Cancel clicked
		scite.StripShow("") 
	end
end

function do_run()
	if status == 'idle' then
	scite_OnOutputLine (handleDebugPrompt,line)
	-- Arjunea Fix lua5.3.4
		if not (props['debug.asktarget']=='' or props['debug.asktarget'] == '0') and (#stripText == 0 ) then
				scite.StripShow("") -- clear strip
				scite.StripShow("!'/todo: rewrite.../ Target name:'["..props['FilePath'].."]((OK))(&Cancel)")
				return
		end
			if lfs then lfs.chdir(props['FileDir']) else os.chdir(props['FileDir'])	end
		if	do_launch() then
			set_status('running')
		else
			print 'Unknown command: unable to spawn process!'
		end
    else        
        RemoveLastMarker(true)
        dbg:continue()
        set_status('running')
    end
end

function do_kill()
	if status== 'running' or status == 'active' then
		if status == 'running' then
			-- this actually kills the debugger process
			spawner_obj:kill()
		else
			-- this will ask the debugger nicely to exit
			dbg:quit()
		end
		 closing_process()
	end
	remove_OnOutputLine(handleDebugPrompt)
end

function do_next()
	if status=="active" then dbg:step_over() end
end

function breakpoint_from_position(lno)
	for b in Breakpoints() do
		if b.file == scite_CurrentFile() and b.line == lno then
			return b
		end
	end
	return nil
end

function do_breakpoint()
	local lno = current_line() + 1
	local file = props['FileNameExt']	
	-- do we have already have a breakpoint here?
	local brk = breakpoint_from_position(lno)
	if brk then
		local bnum = brk.num
		brk:delete()
		if status ~= 'idle' then
			dbg:clear_breakpoint(file,lno,bnum)
		end
	else
		last_breakpoint = SetBreakMarker(lno)
		if  last_breakpoint then			
			if status ~= 'idle' then
				dbg:set_breakpoint(file,lno)
			end
		end
	end
end

function do_temp_breakpoint()
	local lno = current_line() + 1
	local file = props['FileNameExt']
	dbg:gotoL(file,lno)
end

local function char_at(p)
    return string.char(editor.CharAt[p])
end

-- used to pick up current expression from current document position
-- We use the selection, if available, and otherwise pick up the word;
-- if it seems to be a field expression, look for the object before.
local function current_expr(pos)
    local s = editor:GetSelText()
    if s == '' then -- no selection, so find the word
        pos = pos or editor.CurrentPos
        local p1 = editor:WordStartPosition(pos,true)
        local p2 = editor:WordEndPosition(pos,true)
        -- is this a field of some object?
        while true do
            if  char_at(p1-1) == '.' then -- generic member access
                p1 = editor:WordStartPosition(p1-2,true)
            elseif char_at(p1-1) == '>' and char_at(p1-2) == '-' then --C/C++ pointer
                p1 = editor:WordStartPosition(p1-3,true)
            else
                break
            end
        end
        return editor:textrange(p1,p2)
    else
        return s
    end                
end

local function catdbg_write (s)
    catdbg:write(s,'\n')
    catdbg:flush()
end

function do_inspect()
	if status=="active" then
		 local w = current_expr()
		 if len(w) > 0 then
			  if catdbg then dbg:set_display_handler(catdbg_write) end
			  dbg:inspect(w)
		 end
	end	 
end

function do_locals()
	if status=="active" then dbg:locals() end
end

function do_watch()
    if status=="active" then dbg:watch(current_expr()) end
end

function do_backtrace()
	if status=="active" then dbg:backtrace(scite_GetProp('debug.backtrace.depth','20')) end
end

function do_up()
	if status=="active" then dbg:up() end
end

function do_down()
	if status=="active" then dbg:down() end
end

function do_finish()
    if status=="active" then dbg:finish() end
end

local root

function Dbg:parameter_string()
	-- any parameters defined with View|Parameters
    local parms = ' '
    local i = 1
    local parm = props[i]
    while parm ~= '' do
        if find(parm,'%s') then
			-- if it's already quoted, then preserve the quotes
 			if find(parm,'"') == 1 then
 				parm = gsub(parm,'"','\\"')
 			end
            parm = '"'..parm..'"'
        end
        parms = parms..' '..parm
        i = i + 1
        parm = props[i]
    end
    return parms
end

local menu_init = false
local debug_verbose
local debuggers = {}
local append = table.insert
local remove = table.remove

---- event handling

-- If an event returns true, then this event will persist.
-- The return value of this function is true if any event returns an extra true result
-- Note: we iterate over a copy of the list, because this is the only way I've
-- found to make this method re-enterant. With this scheme it is
-- safe to raise an event within an event handler.
function Dbg:raise_event (event,...)
    local events = self.events
    if not events then return end
    -- not recommended for big tables!
    local cpy = {unpack(events)}
    local ignore
    for i,evt in ipairs(cpy) do
        if evt.event == event then
            local keep,want_to_ignore = evt.handler(...)
            if not keep then
               remove(events,i)
            end
            ignore = ignore or want_to_ignore
        end
    end
    return ignore
end

function Dbg:set_event (name,handler)
    if not self.events then self.events = {} end
    append(self.events,{event=name,handler=handler})
end

function Dbg:queue_command (cmd)
    self:set_event('prompt',function() spawner_command(cmd) end)
end

function create_existing_breakpoints()
	os.remove(dbg.cmd_file)
	local out = io.open(slashify(dbg.cmd_file),"w")
	dbg:special_debugger_setup(out)
	dbg:dump_breakpoints(out)
    local parms = dbg:parameter_string()
	dbg:run_program(out,parms)
	out:close();
end


-- you may register more than one debugger class (@dclass) but such classes must
-- have a static method discriminate() which will be passed the full target name.
function register_debugger(name,ext,dclass)
    if type(ext) == 'table' then
        for i,v in ipairs(ext) do
            debuggers[v] = dclas
        end
    else
		if not debuggers[ext] then
			debuggers[ext] = {dclass}
		else
			if not dclass.discriminator then
				error("Multiple debuggers registered for this extension, with no discriminator function")
			end		
			append(debuggers[ext],dclass)
		end
    end
end

function create_debugger(ext,target)
	local dclasses = debuggers[ext]
    if not dclasses then dclasses = debuggers['*'] end
	if #dclasses == 1 then -- there is only one possible debugger for this extension!
		return dclasses[1]
	else -- there are several registered. We need to call the discriminator!
		for i,d in ipairs(dclasses) do
			if d.discriminator(target) then
			
				return d
			end
		end
	end
	error("unable to find appropriate debugger")
end

local initialized
local was_error = false
local continued_line, end_line_action, postproc

function do_launch()
	
	if not menu_init then 
		do_set_menu()
		menu_init = true
	end
	local no_host_symbols
    traced = false
	debug_verbose = true
   	-- *doc* detect the debugger we want to use, based on target extension
    -- if there is no explicit target, then use the current file.
    local target = scite_GetProp('debug.target')
    local ext
    if target then
	    -- @doc the target may not actually have debug symbols, in the case
		-- where we are debugging some dynamic libraries. Indicate this 
		-- by prefixing target with [n]
		if target:find('^%[n%]') then
			target = target:sub(4)
			no_host_symbols = true
		end
        ext = split_last(target,'.') --File Ext
    else
        ext = props['FileExt']
    end
	dbg = create_debugger(ext,choose(target,target,props['FileName']))
	dbg.host_symbols = not no_host_symbols
    -- this isn't ideal!
    root = props['FileDir']
    dbg:init(root)
    do_skip_includes = scite_GetProp('debug.skip.includes',true)
    if do_skip_includes then
		local inc_path
        if GTK then inc_path = '^/usr/' else inc_path = '<<<DONUT>>>' end
		local file_pat_prop = 'debug.skip.file.matching'
		if dbg.skip_system_extension then
			file_pat_prop = file_pat_prop..dbg.skip_system_extension
		end
		skip_file_pattern = scite_GetProp(file_pat_prop,inc_path)
    end
    -- *doc* the default target depends on the debugger (it wd have extension for pydb, etc)
    if not target then target = dbg:default_target() end
    target = quote_if_needed(target)    
    -- *doc* this determines the time before calltips appear; you can set this as a SciTE property.
	if props['dwell.period'] == '' then props['dwell.period'] = 200 end
    -- get the debugger process command string
    local dbg_cmd = dbg:command_line(target)
    print(dbg_cmd)
    continued_line = nil
    -- first create the cmd file for the debugger
	create_existing_breakpoints()    
	if scite_GetProp('debug.output') then
		catdbg = io.open('/tmp/scite-debug-out','w')
	else
		catdbg = nil
	end
    --- and go!!
    spawner.verbose(scite_GetPropBool('debug.spawner.verbose',true))

	 spawner.fulllines(1)	
	spawner_obj = spawner.new(dbg_cmd)
	spawner_obj:set_output('ProcessChunk')
	spawner_obj:set_result('ProcessResult')
	return spawner_obj:run()    
end

-- speaking to the spawned process goes through a named pipe on both
-- platforms.
local pipe = nil
local last_command_line

function dbg_command_line(s)
    if status == 'active' or status == 'error' then
        spawner_command(s)
        last_command_line = s
        if dbg.trailing_prompt then
            last_command_line = dbg.prompt..last_command_line
        end    
    end
end

function spawner_command(line)
	spawner_obj:write(line..'\n')
end

--local ferr = io.stderr

function dbg_command(s,argument)
	dbg.last_command = s
    dbg.last_arg = argument
    if argument then s = s..' '..argument end
    dbg_command_line(s)
end

-- *doc* currently, only win32-spawner understands the !up command; I can't
-- find the Unix/GTK equivalent! It is meant to bring the debugger
-- SciTE instance to the front.
function raise_scite()
	spawner.foreground()
end

-- output of inspected variables goes here; this mechanism allows us
-- to redirect command output (to a tooltip in this case)
function display(s)
	if dbg.result_handler then
		dbg.result_handler(s)
        dbg.result_handler = nil
	else
		print(s)
	end
end

function closing_process()
    print 'quitting debugger'
	 stripText=""
	 --spawner_obj:close()
    set_status('idle')
    if catdbg ~= nil then print(catdbg); catdbg:close() end
	scite_LeaveInteractivePrompt()
	RemoveLastMarker(true)
	os.remove(dbg.cmd_file)
end

local function finish_pending_actions()
    if continued_line then
        end_line_action(continued_line,dbg)
        continued_line = nil
        if postproc.once then dbg.last_command = ''  end
    end
end

local function set_error_state()
    if was_error then
        set_status('error')
        was_error = false
    else
        set_status('active')
    end
end

local function auto_backtrace()
    if status == 'error' and not traced then
        raise_scite()
        do_backtrace()
        traced = true
    end
end

local current_file

local function error(s)
    io.stderr:write(s..'\n')
end

local was_prompt

function ProcessOutput(line)
    -- on the GTK version, commands are currently echoed....
    if last_command_line and find(line,last_command_line) then
        return
     end
-- Debuggers (esp. clidebug) can emit spurious blank lines. This makes them quieter!
	 if was_prompt and line:find('^%s*$') then
		was_prompt = false
		return
	end
--~  	 print('*',line)
    -- sometimes it's useful to know when the debugger process has properly started
    if dbg.detect_start and find(line,dbg.detect_start) then
        dbg:handle_debug_start()
        dbg.detect_start = nil
        return
    end
	-- detecting end of program execution
    local prog_ended,process_fininished = dbg:detect_program_end(line)
	if prog_ended then
		if not processed_finished then spawner_command('quit') end
        set_status('idle')
        closing_process()
		return
	end
    -- ignore prompt; this is the point at which we know that commands have finished
	if find(line,dbg.prompt) then
        dbg:raise_event 'prompt'
        finish_pending_actions()
        if was_error then set_error_state() end
        auto_backtrace()
		  was_prompt = true
		  return
	end

    -- the result of some commands require postprocessing;
	-- it will collect multi-line output together!
    postproc = dbg.postprocess_command[dbg.last_command]
    if postproc then
        local tline = rtrim(line)
        if find(tline,postproc.pattern) 
			or (postproc.alt_pat and find(tline,postproc.alt_pat)) then            
            if not postproc.single_pattern then 
                finish_pending_actions()
                continued_line = tline                
                end_line_action = postproc.action
            else
                postproc.action(tline,dbg)
            end
        else
            if continued_line then continued_line = continued_line..tline end
        end
    end
	-- did we get a confirmation message about a created breakpoint?
    dbg:breakpoint_confirmation(line)
	-- have we crashed?
	if dbg:detect_program_crash(line) then
		was_error = true
	end
	-- looking for break at line pattern 
	local file,lineno,explicit_error = dbg:find_execution_break(line)
	if file and status ~= 'idle' then
        if dbg.check_skip_always or current_file ~= file then
            current_file = file
            if dbg:auto_skip_over_file(file) then
                dbg:finish()
                spawner_command('step') --??
                return
            end
        end
		-- a debugger can indicate an explicit error, rather than depending on
		-- detect_program_crash()
		if explicit_error then
			was_error = true
		end
        set_error_state()
        -- if any of the break events wishes, we can ignore this break...
        if not dbg:raise_event ('break',file,lineno,status)  then
            OpenAtPos(file,lineno,status)
            raise_scite()
            auto_backtrace()
            dbg.last_comand = ''
        end
	else
        local cmd = dbg.last_command
        if (debug_verbose or dbg.last_command == '<inter>') and
			not (dbg.silent_command[cmd] or dbg.postprocess_command[cmd]) then
				trace(line)
        end
	end
end

function ProcessChunk(s)
	local i1 = 1
	local i2 = find(s,'\n',i1)
	while i2 do
		local line = sub(s,i1,i2)
		ProcessOutput(line)
		i1 = i2 + 1
		i2 = find(s,'\n',i1)		
	end
	if i1 <= len(s) then
		local line = sub(s,i1)
		ProcessOutput(line)
	end
end

function ProcessResult(res)
	if status ~= 'idle' then
		closing_process()
	end
end

--- *doc* currently, double-clicking in the output pane will try to recognize
--- a stack frame pattern and move to that frame if possible.
scite_OnDoubleClick(function()
	if output.Focus and status == 'active' or status == 'error' then
		dbg:detect_frame(output:GetLine(current_output_line()))
	end
end)

-- *doc* if your scite has OnDwellStart, then the current symbol under the mouse
-- pointer will be evaluated and shown in a calltip.
local _pos

function calltip(s)
    editor:CallTipShow(_pos,s)
end

scite_OnDwellStart(function (pos,s)
    if status == 'active' or status == 'error' then
        if s ~= '' then
			s = current_expr(pos)
            _pos = pos
            dbg:set_display_handler(calltip)            
			dbg:inspect(s)
        else
           editor:CallTipCancel()
        end
        return true
    end
end)

--
-- Load all debug interface classes
--
if (props["debug.path"]=="") then 
	print("debugger.lua: Error- Please define $(debug.path) ")
	return false
end

dbgIntsPath=props["debug.path"]..dirsep.."dbgInterfaces"..dirsep.."*.lua"
for i,file in pairs(scite_Files(dbgIntsPath)) do
  dofile(file)
end
