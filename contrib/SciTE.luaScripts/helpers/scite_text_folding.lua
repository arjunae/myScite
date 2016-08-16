-- folding text documents in SciTE

local strfind = string.find
local strlen = string.len
local gfind = string.gfind

scite_Command {
  'Show Outline|toggle_outline',
  'Rescan|process_file $(FilePath)',
}

local function setup_styles()
   local font = scite_GetProp('text.font.name')
   if font then editor.StyleFont[0] = font end
end

function toggle_outline()
  for i = 0,editor.LineCount-1 do
     if editor.FoldLevel[i] < SC_FOLDLEVELHEADERFLAG then
        editor:HideLines(i,i)
     end
  end   
end

local function set_level(i,lev,fold)
  local foldlevel = lev + SC_FOLDLEVELBASE
  if fold then 
     foldlevel = foldlevel + SC_FOLDLEVELHEADERFLAG
     editor.FoldExpanded[i] = true
  end
  editor.FoldLevel[i] = foldlevel
end

-- we need to know if a line is a fold point;
-- this is ad-hoc code that doesn't work for
-- richer fold info!
local function get_level(i)
  local fold = false
  local level_flags = editor.FoldLevel[i] - SC_FOLDLEVELBASE
  if level_flags - SC_FOLDLEVELHEADERFLAG >= 0 then
    fold = true
    level_flags = level_flags - SC_FOLDLEVELHEADERFLAG 
  end
  return level_flags, fold  
end

local txt_extensions = {}
local txt_ext_prop = nil
local file_ext

local function is_text_file(file)
  local te = props['text.ext']  
  if te ~= txt_ext_prop then
     txt_ext_prop = te
     if te == '' then txt_extensions['txt'] = true
     else -- expecting something like '*.txt;*.doc' etc
       for w in string.gfind(txt_ext_prop,'[^;]+') do
          local ext = string.sub(w,3)
          txt_extensions[ext] = true
        end
     end
  end
  file_ext = props['FileExt']  
  local ret = txt_extensions[file_ext]
  if not ret and scite_GetProp 'PLAT_WIN' then
     ret = txt_extensions[string.lower(file_ext)]
  end
  return ret
end

local lev=0
local in_text_file
local outline_pat = '^(=+)'
local start_depth
local looking_for_number,explicit_match1,explicit_match2
local txt_files = {}
local parse_fold_line

local function explicit_match(line)
     if strfind(line,explicit_match1) then return 1 end
     if explicit_match2 then
          if strfind(line,explicit_match2) then return 2 end
     end
end

local function number_match(line)
     if strfind(line,'^%d+%.') then 
        local _,_,heading = strfind(line,'([%d%.]+)')
        local k = 0
        for x in gfind(heading,'[^%.]+') do k = k + 1 end
        return k
    end  
end

local function prefix_match(line)
     local _,_,prefix = strfind(line,outline_pat)
     if prefix then
         return strlen(prefix) - start_depth
     end 
end

function process_line(i,line)
   local depth = parse_fold_line(line)
   if depth then
	lev = depth
        set_level(i,lev-1,true)
   else
        set_level(i,lev)
   end 
end

-- there are some characters which are 'magic'
-- in Lua regular expressions.  These need to be quoted.
local function regexp_quote(ch)
  if strfind('.*()+-',ch) then
    return '%'..ch
  else
    return ch
  end
end

function process_file(file)  
  in_text_file = is_text_file(file)
  if not in_text_file then return end
  txt_files[file] = true
  -- here we look at stylings, etc particular to text documents
  if scite_GetProp('text.outline.number',0) == 1 then
      parse_fold_line = number_match
  end
  explicit_match1 = scite_GetProp('text.outline.match1')
  explicit_match2 = scite_GetProp('text.outline.match2')
  if explicit_match1 then
     parse_fold_line = explicit_match
  else
     parse_fold_line = prefix_match
     local och = regexp_quote(scite_GetProp('text.outline.char','='))
     outline_pat = '^('..och..'+)'
     start_depth = scite_GetProp('text.outline.start',0)
  end
  setup_styles()
  local n = editor.LineCount
  lev = 0
  for i = 0,n-2 do  -- n-2??
      process_line(i,editor:GetLine(i))
  end
end

-- yes, this can all be done w/out extman! 
-- But OnEditorLine() is not a builtin SciTE event,
-- so check the extman source for the implementation.

scite_OnSwitchFile(process_file)
scite_OnOpen(process_file)
scite_OnBeforeSave(function(file)
  if not txt_files[file] then
     process_file(file)
  end
end)

scite_OnEditorLine(function(line)
  if in_text_file then
    -- No. of line we have just entered
    local l = editor:LineFromPosition(editor.CurrentPos) - 1
    if l < 0 then return end
    local nlev,fold
    if l < 0 then
      nlev,fold = 0,false
    else
      nlev,fold = get_level(l-1)      
    end
    if not fold then lev = nlev 
                else lev = nlev + 1
                end
    set_level(l+1,lev)
    process_line(l,line)
  end
end)

--[[  -- for debugging--
scite_OnDoubleClick(function()
  print(editor.CurrentPos)
  editor:GotoPos(editor.CurrentPos)-- get rid of the selection!
  local l = editor:LineFromPosition(editor.CurrentPos)
  print(get_level(l))
end)
]]

