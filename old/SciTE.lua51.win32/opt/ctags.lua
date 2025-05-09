--[[

-- Browse a tags database from SciTE!
-- 02.12.2017 -> Arjunae: 
-- Extman support / project.ctags.filename / project.path /  project.ctags.list_one & ALT-Click Tag!
--
-- Set this property:
-- project.ctags.filename=<full path to tags file>
-- 1. Multiple tags are handled correctly; a drop-down list is presented
--     Define project.ctags.list_one="1" to force showing a list for single entries.
-- 2. There is a full stack of marks available.
-- 3. If $(project.path) is not defined, will try to find a tags file in the current dir.
-- 4. if $(project.path) is defined assume --tag-relative=yes  (Tags relative to project.path)
--     otherwise assume fully qualified Pathes in Tagfile

]]
local GTK = scite_GetProp('PLAT_GTK')
if GTK then dirSep="/" else dirSep="\\" end
  
if scite_Command then
scite_Command {
  'Find Tag|find_ctag  $(CurrentWord)|Ctrl+.',
--   'Go to Mark|goto_mark|Alt+.',
--  'Set Mark|set_mark|Ctrl+\'',
--   'Select from Mark|select_mark|Ctrl+/',
}
end

local gMarkStack = {}
local gMarkStack = {}
local sizeof = table.getn
local push = table.insert
local pop = table.remove
local top = function(s) return s[sizeof(s)] end
local _UserListSelect


-- Parse string
local function eval(str)
    if type(str) == "string" then
        return loadstring("return " .. str)()
    elseif type(str) == "number" then
        return loadstring("return " .. tostring(str))()
    else
        error("is not a string")
    end
end

-- this centers the cursor position
-- easy enough to make it optional!
local function ctags_center_pos(line)
  if not line then
     line = editor:LineFromPosition(editor.CurrentPos)
  end
  local top = editor.FirstVisibleLine
  local middle = top + editor.LinesOnScreen/2
  editor:LineScroll(0,line - middle)
end

local function open_file(file,line,was_pos)
  scite.Open(file)
  if not was_pos then
    editor:GotoLine(line)
    ctags_center_pos(line)
  else
    editor:GotoPos(line)
    ctags_center_pos()
  end
end

local function set_mark()
  push(gMarkStack,{file=props['FilePath'],pos=editor.CurrentPos})
end

function goto_mark()
 local mark = pop(gMarkStack)
 if mark then
    open_file(mark.file,mark.pos,true)
 end
end

function select_mark()
local mark = top(gMarkStack)
print (mark)
if mark then
    local p1 = mark.pos
    local p2 = editor.CurrentPos
    print(p1..','..p2)
    editor:SetSel(p1,p2)
 end
end

local find = string.find

local function extract_path(path)
-- given a full path, find the directory part
 local s1,s2 = find(path,'/[^/]+$')
 if not s1 then -- try backslashes!
    s1,s2 = find(path,'\\[^\\]+$')
 end
 if s1 then
    return string.sub(path,1,s1-1)
 else
    return nil
 end
end

local function ReadTagFile(file)
 -- if not tags then return nil end
  local f = io.open(file)
  if not f then return nil end
  local tags = {}
  -- now we can pick up the tags!
  for line in f:lines() do
    -- skip if line is comment
    if find(line,'^[^!]') then
        local _,_,tag = find(line,'^([^\t]+)\t')
        local existing_line = tags[tag]
        if not existing_line then
            tags[tag] = line..'@'
        else
            tags[tag] = existing_line..line..'@'
        end
    end
  end
  return tags
end

local function parseTagEntry(foundTags)
	local ptTagName="([^\t]*).*" -- [linestart TAB] , tag_name ,  TAB
	local ptFileName="\t([.a-zA-z0-9\\/ ]*)[ \t]*" --  TAB, file_name, [SPACE TAB]
	local ptLineNum="([0-9]*);.*"
	local ptTagPatt=".*^(.*)$.*" -- any, wordstart, funcDef, $
	local ptTagProp=".*;\"\t(.)" -- any, [;\"TAB], tag_prop
	local ptTagClass=";\"\t.\t(.*\t.*)$" -- pt_tagProp, TAB, tagClass	
	local s1,s2,file_name = find(foundTags, ptFileName)
	local s1,s2,line_num = find(foundTags, ptLineNum)
	local s1,s2,tag_pattern = find(foundTags, ptTagPatt)
	local s1,s2,tag_prop = find(foundTags, ptTagProp)
	local s1,s2,tag_class =find(foundTags, ptTagClass)
	local s1,s2,tag_name = find(foundTags, ptTagName)
	
  --logging=true
   if(logging) then
		print(s1)
		print(s2)
		print(tag_name)
		print(file_name)
		print(line_num)
		print(tag_pattern)
		print(tag_prop)
		print(tag_class)
   end
  
  return s1,s2,tag_name,file_name,line_num,tag_pattern,tag_prop,tag_class
end

local gTagFile
local tags

local function OpenTag(tag)
  -- ask SciTE to open the file
  
  if not tag then return end
  local fileNamePath
  local path= extract_path(gTagFile)

  if path  then fileNamePath= tag.file end
  if props["project.path"]~="" then fileNamePath = path..dirSep..tag.file end --Project relative Path
  set_mark()
  scite.Open(fileNamePath)
  -- depending on what kind of tag, either search for the pattern,
  -- or go to the line.
  local pattern = tag.pattern

  if type(pattern) == 'string' then
    local p1 = editor:findtext(pattern)
    if p1 then
       editor:GotoPos(p1)
       ctags_center_pos()
    end
  else
    local tag_line = pattern
    editor:GotoLine(tag_line)
    ctags_center_pos(tag_line)
  end
end

local function find_ctag(f,partial)
  -- search for tags files first
  local result
  result = props['project.path'] ..dirSep.. props['project.ctags.filename']
  if not result then result = locate_tags(props['FileDir']) end
  if not result then
    print("tag file ".. result.." not found!")
    return
  end

  -- tagFile found
  if result ~= gTagFile then
    --print("About to read tags from:"..result)
    gTagFile = result
    tags = ReadTagFile(gTagFile)
  end
  -- search tagName, append if neccecary
  if tags == nil then return end
  if partial then
    result = ''
    for tag,val in tags do
       if find(tag,f) then
         result = result..val..'@'
       end
    end
  else
    result = tags[f]
  end

  if not result then 
   -- print("No tags found" )
    return
  else
  -- print("Tag(s) found:\n"..result)  
  end 
  
  local matches = {}
  local k = 0;
  
  -- parse concatenated TagEntries 
  for line in string.gfind(result,'([^@]+)@') do
		k = k + 1
		-- factored to parseTagEntry to ease debugging. 
		local s1,s2,tag_name,file_name,line_num,tag_pattern,tag_prop,tag_class=parseTagEntry(line)
		--local s1,s2,tag_name,file_name,tag_pattern,tag_property = find(line,'([^\t]*)\t([^\t]*)\t/^(.*)$/;\"\t(.*)')

		if line_num ~= "" then --option: Only show the tag_name within the selectBox
			tag_pattern=tag_name
		end
		
		if s1 ~= nil then
		  tag_pattern = tag_pattern:gsub('\\/','/')
		  matches[k] = {tag=f,file=file_name,pattern=tag_pattern,property=tag_property}
		end
  end

  -- early exit, if loops pattern failed
  if k == 0 then return end

  -- show a listbox if  only one/multiple entries has been found.
  if k > 1  or props["project.ctags.list_one"]=="1"  then 
    local list = {}
    for i,t in ipairs(matches) do
      table.insert(list,i..' '..t.file..':'..t.pattern)
    end

    scite_UserListShow(list,1,function(s)
       local _,_,tok = find(s,'^(%d+)')
       local idx = tonumber(tok) -- very important!
       OpenTag(matches[idx])
      end
    )
  else
      OpenTag(matches[1]) 
  end
end

local function locate_tags(dir)

    local filefound = nil
    local slash, f
    _,_,slash = string.find(dir,"([/\\])")
    while dir do
        file = dir .. slash .. "tags"
        --print ( "---" .. file)
        f = io.open(file)
        if f then
            filefound = file
            break
        end
        _,_,dir = string.find(dir,"(.+)[/\\][^/\\]+$")
        --print(dir)
    end
    return filefound
end

function reset_tags()
    gTagFile = nil
    tags     = {}
end

--
-- wordAtPosition()
-- Returns the whole keyword under the cursor
--
local function wordAtPosition()
  local pos = editor.CurrentPos
  local startPos=pos
  local lineEnd = editor.LineEndPosition[editor:LineFromPosition(pos)]
  local whatever,endPos = editor:findtext("[^a-zA-z0-9_-*]",SCFIND_REGEXP,pos,lineEnd) --words EndPos
  if not endPos then endPos=lineEnd end
  local tmp=""
  
  --search backwards for a Delimiter
  while not string.find(editor:textrange(startPos,startPos+1),"[^%w_-]+")  do
    startPos=startPos-1
  end
  tmp=editor:textrange(startPos+1,endPos-1)
  tmp=string.match(tmp,"[%w_-]+") -- just be sure. only return the keyword
 -- print("searching for:"..tmp)
  return tmp
end

--
-- checks for modifierKeys used during the click event
-- changes/restores userlist Font Size
--
function modifiers(shift,strg,alt,x)

  if (OnDoubleClick or OnChar or OnSwitchFile) and not scite_Command then
    print("ctagsd.lua>There is a handler conflict, please use extman")
    return
  end

  if alt==true then
    find_ctag (wordAtPosition()) 
  end
 
end

scite_OnClick(modifiers)
