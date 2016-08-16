-- macro substitution in Lua

local args = {}
local substitutions = {}
local find = string.find
local sub = string.sub

function quote(x)
  if not find(x,'\n') then
    return '\"'..x..'\"'
  else
    return '[['..x..']]'
  end
end
function cat(x,y) return x..y end

-- these are refered to in the examples --

function upcase(x) return string.upper(x) end

function insert_file(file)
  local f = io.open(file)
  local txt = f:read('*a')
  if txt then
    f:close()
    return txt
  else
    return ""
  end
end

function do_class(name,base)
 local res = 'class '..name
 if base then 
    res = res..': public '..base
 end
 return res..' {\n public:\n};\n'
end

function convert_to_iden(x)
  local s = string.upper(x)
  s = string.gsub(s,'[^%w_]','_')
  return string.sub(s,1,32)
end

function international_string(x)
  local id = convert_to_iden(x)
  local f = io.open('international.h','a')
  f:write('#define '..id..' '..quote(x)..'\n')
  f:close()
  return id
end

-- break up comma-separated lists, but be careful to leave
-- alone commas within nested parentheses!
local function grab(str)
  local res = {}
  local append = table.insert
  local sub = string.sub
  local function char(s,i) return sub(s,i,i) end
  local n = string.len(str)
  local i1,i2=1,1
  local level = 0
  for i = 1,n do
    local ch = char(str,i)
    if ch == '(' then level = level + 1 
    elseif ch == ')' then level = level - 1
    elseif ch == ',' and level == 0 then
      append(res,sub(str,i1,i-1))
      i1 = i+1
    end
  end
  append(res,sub(str,i1))
  return res
end

-- parse macro expressions like 'FOR(i,n)'
local function split_args(str)
   local _,_,name,args = find(str,'([%w_]+)%((.+)%)$')
   if name then 
      return name,grab(args)
   end
end

-- this function is global because you can use it in macro definitions!
function add_macro(str)
  local _,_,macro,subst = find(str,'([^=]+)=(.+)$')
  local name,arguments  = split_args(macro)
  if name then -- our macro had args
	args[name] = arguments
  else
	name = macro
  end
  substitutions[name] = subst
  return ''
end

local function preprocess_macros()
  local i = 1
  while true do
    local str = props['macro.subst.'..i]
    if str and str ~= '' then add_macro(str) else break end
    i = i + 1
  end
end

local function substitute(name,actual_args)
  local size_of = table.getn
  local subst = substitutions[name]
  local res
  if subst then -- this is a macro!
     local formal_args = args[name]
     if formal_args then 
    -- we must substitute the actual args
        local subst_table = {}
        local na = size_of(actual_args)
        for i = 1,size_of(formal_args) do
            local subst
            if i <= na then subst = actual_args[i]
                       else subst = '' end
            subst_table[formal_args[i]] = subst
 	end
        res = string.gsub(subst,'([%w_]+)',function(arg)
                  local repl = subst_table[arg]
                  return repl or arg
		end)
     else
        res = subst
     end
     -- find any embedded Lua calls and evaluate them!
     -- These are of form $<name>(simple list of args)\
        res = string.gsub(res,'%$([%w_]*)(%b())',function(lname,argstr)
                  -- break '(args)' into a list of arguments and quote all vars
                  local argl = grab(sub(argstr,2,-2))                  
                  if lname ~= 'eval' then
                    for i,v in argl do
                      if not find(v,'^[\"\'%d]') then  
                        argl[i] = quote(v)
                      elseif v == '' then
                        argl[i] = 'nil'
                      end
                  end
                    expr ='return '..lname..'('..table.concat(argl,',')..')' 
                  else
                    expr = 'return '..argl[1]
                  end
                  local chunk = loadstring(expr)
                  if chunk then return chunk()
                  else error('failed to evaluate Lua function!') end
               end)
      -- finally, replace '\\n' with a linefeed..
      res = string.gsub(res,'\\n','\n')
  end
  return res
end

local byte = string.byte
local whitespace = {[32] = true, [9] = true, [10] = true, [13] = true}
local alnum = {}

function do_macro()
  local function char_at(i) return editor.CharAt[i] end
  local function as_str(ch) return string.char(ch)  end

  local function eq(ch)
    local byteval = byte(ch)
    return function(code) return code == byteval end
  end

  local function not_whitespace(code)
    return not whitespace[code]
  end

  local function not_alnum(code)
    return not alnum[code]
  end

  local function skip_back_until(cmpfn,p)
    while p >= 0 and not cmpfn(char_at(p)) do      
      p = p-1
    end
    return p
  end
  
  local p = editor.CurrentPos
  local endp = p
  p = p - 1
  local start_arg,end_name,start_name,args
  local ch = as_str(char_at(p))
  if ch == '\'' or ch == '\"' then 
     p = skip_back_until(eq(ch),p-1)      
     start_arg  = p 
  elseif ch == ')' then
     p  = skip_back_until(eq('('),p-1)
     start_arg = p
  else
     start_arg  = nil
  end
  if start_arg then
     args = editor:textrange(start_arg,endp)
     args = string.sub(args,2,-2) -- strip the quotes or parens
     p = skip_back_until(not_whitespace,p-1)
     end_name = p+1
  else
     end_name = endp
  end
  start_name = skip_back_until(not_alnum,p) + 1
  local name = editor:textrange(start_name,end_name)
  editor:SetSel(start_name,endp)
  local arglist
  if args then arglist = grab(args) end
  local subt = substitute(name,arglist)
  editor:ReplaceSel(subt)  
end

function macro_select()
  local arg = {editor:GetSelText()}
  local subt = substitute('_',arg)
  editor:ReplaceSel(subt)
end

local function set_alnum_range(i1,i2)
     for i = i1,i2 do alnum[i] = true end
end
set_alnum_range(byte('0'),byte('9'))
set_alnum_range(byte('a'),byte('z'))
set_alnum_range(byte('A'),byte('Z'))
alnum[byte('_')] = true

preprocess_macros()

