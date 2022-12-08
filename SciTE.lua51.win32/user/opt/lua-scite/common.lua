-- COMMON.lua -- 
local sub = string.sub
local append = table.insert
local find = string.find
if lpeg==nil then err,lpeg = pcall( require,"lpeg")  end
---------------
--
-- File and Path related functions, used in debugger.lua
--
---------------
-- returns i characters at position s as a string
--
local function at (s,i)
    return s:sub(i,i)
end
--- note: for finding the last occurance of a character, it's actualy
--- easier to do it in an explicit loop rather than use patterns.
--- (These are not time-critcal functions)
local function split_last (s,ch)
    local i = #s
    while i > 0 do
        if at(s,i) == ch then
            return s:sub(i+1),i
        end
        i = i - 1
    end
end
--
-- return a files name without ext
--
function basename(s)
    local res = split_last(s,dirsep)
    if res then return res else return s end
end
--
-- return a files path
--
function path_of (s)
	local basename,idx = split_last(s,dirsep)
	if idx then
		return s:sub(1,idx-1)
	else
		return ''
	end
end
--
-- return a filenames extension
--
function extension_of (s)
    return split_last(s,'.')
end
--
-- return a filename with ext from its full qualified path
--
function filename(path)
    local fname = basename(path)
    local _,idx = split_last(fname,'.')
    if idx then return fname:sub(1,idx-1) else return fname end
end
--
-- return a filename with ext from its full qualified path
--
function filename(path)
    local fname = basename(path)
    local _,idx = split_last(fname,'.')
    if idx then return fname:sub(1,idx-1) else return fname end
end
function choose(cond,x,y)
	if cond then return x else return y end
end
--
-- word information functions
--
function join(path,part1,part2)
	local res = path..dirsep..part1
    if part2 then return res..dirsep..part2 else return res end
end
-- use scite api to get current files path
function fullpath(file)
	return props['FileDir']..dirsep..file
end
--
-- split a string to a table
--
function split(s,re)
	local i1 = 1
	local sz = #s
	local ls = {}
	while true do
		local i2,i3 = s:find(re,i1)
		if not i2 then
			append(ls,s:sub(i1))
			return ls
		end
		append(ls,s:sub(i1,i2-1))
		i1 = i3+1
		if i1 >= sz then return ls end
	end
end
--
-- split a list
--
function split_list(s)
	return split(s,'[%s,]+')
end
--
-- remove \r\n from a string
--
function strip_eol(s)
	if at(s,-1) == '\n' then
		if at(s,-2) == '\r' then
			return s:sub(1,-3)
		else
			return s:sub(1,-2)
		end
	else
		return s
	end
end
--
-- remove trailing whitespace
--
function rtrim(s)
    return string.gsub(s,'%s*$','')
end
--
-- wordAtPosition()
-- Returns the whole keyword under the cursor
--
local function CurrentWord()
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
  return string.match(tmp,"[%w_-]+") -- just be sure. only return the keyword
end
--------
--
-- line information functions --
--
--------
function current_line()
	return editor:LineFromPosition(editor.CurrentPos)
end
function current_output_line()
	return output:LineFromPosition(output.CurrentPos)
end
-- start position of the given line; defaults to start of current line
function start_line_position(line)
	if not line then line = current_line() end
	return editor.LineEndPosition[line]
end
--
-- returns the word and its position directly behind the cursor.
--
function word_at_cursor()
	local pos = editor.CurrentPos
	local line_start = start_line_position()
	-- look backwards to find the first non-word character!
	local p1,p2 = editor:findtext(NOT_WORD_PATTERN,SCFIND_REGEXP,pos,line_start)
	if p1 then
		return editor:textrange(p2,pos),p2
	end
end
--
-- centers the cursor position
-- easy enough to make it optional!
--
function center_line(line)
	if not line then line = current_line() end
	local top = editor.FirstVisibleLine
	local middle = top + editor.LinesOnScreen/2
	editor:LineScroll(0,line - middle)
end
-- Trims space chars from a strings end
function rtrim(s)
    return string.gsub(s,'%s*$','')
end
----------
--
-- colour information functions --
--
---------
-- allows you to use standard HTML '#RRGGBB' colours;
function colour_parse(str)
	-- Wo for nil value
	if str == nil then str ="#AAFFAA" end
	return tonumber(sub(str,6,7)..sub(str,4,5)..sub(str,2,4),16)
end
--
-- converts a colour to windows format, 
-- brings up guis colour dialouge
-- change the current doc to that colour
--
function edit_colour ()
	local function get_prevch (i)
		return editor:textrange(i-1,i)
	end
	local function get_nextch (i)
		return editor:textrange(i,i+1)
	end
	local function hexdigit(c)
		return c:find('[0-9a-fA-F]')==1
	end
	local i = editor.CurrentPos
	-- let's find the start of this colour field...
	local ch = get_prevch(i)
	while i > 0 and ch ~= '#' and hexdigit(get_prevch(i)) do
		i = i - 1
		--ch = get_prevch(i)
	end
	if i == 0 then return end
	local istart = i
	-- skip the '#'
	if ch == '#' then
		istart = istart - 1
	end
	if get_nextch(i) == '#' then
		i = i+1
	end
	-- let's find the end of this colour field...
	while hexdigit(get_nextch(i)) do
		i = i + 1
	end
	-- extract the colour!
	local colour = editor:textrange(istart,i)
	colour = gui.colour_dlg(colour)
	if colour then -- replace the colour in the document
		editor:SetSel(istart,i)
		editor:ReplaceSel(colour)
	end
end
--
-- Convert a Documents encoding from and to UTF8
--
function switch_encoding()
	--editor:BeginUndoAction()
	editor:SelectAll()
	editor:Copy()
	if editor.CodePage == SC_CP_UTF8 then
		scite.MenuCommand(IDM_ENCODING_DEFAULT)
	else
		scite.MenuCommand(IDM_ENCODING_UCOOKIE)
	end
	editor:Paste()
	scite.SendOutput(SCI_SETCODEPAGE, editor.CodePage)
	--editor:EndUndoAction()
end
--
-- EditorMarkText
--
function EditorMarkText(start, length, style_number)
	local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
	scite.SendEditor(SCI_SETINDICATORCURRENT, style_number)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
	scite.SendEditor(SCI_SETINDICATORCURRENT, current_mark_number)
end
--
-- EditorClearMarks
--
function EditorClearMarks(style_number, start, length)
	local _first_style, _end_style, style
	local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
	if style_number == nil then
		_first_style, _end_style = 0, 31
	else
		_first_style, _end_style = style_number, style_number
	end
	if start == nil then
		start, length = 0, editor.Length
	end
	for style = _first_style, _end_style do
		scite.SendEditor(SCI_SETINDICATORCURRENT, style)
		scite.SendEditor(SCI_INDICATORCLEARRANGE, start, length)
	end
	scite.SendEditor(SCI_SETINDICATORCURRENT, current_mark_number)
end
--
-- Get Start Word
--
function GetStartWord()
	local current_pos = editor.CurrentPos
	return editor:textrange(editor:WordStartPosition(current_pos, true),current_pos)
end
--
-- os_copy
--
function os_copy(source_path,dest_path)
	local function unwind_protect(thunk,cleanup)
		local ok,res = pcall(thunk)
		if cleanup then cleanup() end
		if not ok then error(res,0) else return res end
	end
	local function with_open_file(name,mode)
		return function(body)
		local f, err = io.open(name,mode)
		if err then return end
		return unwind_protect(function()return body(f) end,
			function()return f and f:close() end)
		end
	end
	return with_open_file(source_path,"rb") (function(source)
		return with_open_file(dest_path,"wb") (function(dest)
			assert(dest:write(assert(source:read("*a"))))
			return true
		end)
	end)
end
--
-- ifnil
--
function ifnil(prop, def)
	local val = props[prop]
	if val == nil or val == '' then
		return def
	else
		return val
	end
end
--
-- Translate color from RGB to win
--
local function encodeRGB2WIN(color)
	if color == nil then return nil end
	if string.sub(color,1,1)=="#" and string.len(color)>6 then
		return tonumber(string.sub(color,6,7)..string.sub(color,4,5)..string.sub(color,2,3), 16)
	else
		return color
	end
end
--
-- Translate INDIC_*
--
local function GetStyle(mark_string)
	local mark_style_table = {
		plain    = INDIC_PLAIN,    squiggle = INDIC_SQUIGGLE,
		tt       = INDIC_TT,       diagonal = INDIC_DIAGONAL,
		strike   = INDIC_STRIKE,   hidden   = INDIC_HIDDEN,
		roundbox = INDIC_ROUNDBOX, box      = INDIC_BOX
	}
	return mark_style_table[mark_string]
end
--
-- Init Mark Style
--
local function InitMarkStyle(mark_number, mark_style, color, alpha)
	editor.IndicStyle[mark_number] = mark_style
	editor.IndicFore[mark_number]  = encodeRGB2WIN(color)
	editor.IndicAlpha[mark_number] = alpha
	editor.IndicUnder[mark_number] = true
end
--
-- Parse Mark Style From Prop String
--
function ParseMarkStyle(prop_string)
	local mark = props[prop_string]
	local ret_number = 8
	if mark ~= "" then
		local mark_number= tonumber(mark:match("%d+")) or 30
		local mark_color = mark:match("#%x%x%x%x%x%x") or (props["find.mark"]):match("#%x%x%x%x%x%x") or "#0F0F0F"
		local mark_style = GetStyle(mark:match("%l+")) or INDIC_ROUNDBOX
		local alpha_fill = tonumber((mark:match("%@%d+") or ""):sub(2)) or 30
		InitMarkStyle(mark_number, mark_style, mark_color, alpha_fill)
		ret_number = mark_number
	end
	return ret_number
end
--------------------------
--
-- Custom Common Functions --
--
--
-- check if current Docs charset is Unicode using lpeg regexp 
-- if found, switches Current docs mode to (UTF-8) 

function CheckUTF8()
	if lpeg==nil then return end
	local text = editor:GetText()
	local cont = lpeg.R("\128\191")   -- continuation byte
	local utf8 = lpeg.R("\0\127")^1
			+ (lpeg.R("\194\223") * cont)^1
			+ (lpeg.R("\224\239") * cont * cont)^1
			+ (lpeg.R("\240\244") * cont * cont * cont)^1
	local latin = lpeg.R("\0\127")^1
	local searchpatt = latin^0 * utf8 ^1 * -1
	if searchpatt:match(text) then
		props["encoding"]="(UTF8)"
		scite.MenuCommand(IDM_ENCODING_UCOOKIE)
	else
		props["encoding"]=""
	end
end
--
-- Enables above UTF-8 checking via property 
--
function DetectUTF8()
	if props["editor.detect.utf8"] == "1" then
		if editor.CodePage ~= SC_CP_UTF8 then
			CheckUTF8()
		end
	end
end
--
-- retrieve a HTTP URL
-- write result to envVar
--
function fetchHTTP(sURL)
	if props["httpResponse"]~="" then return end
	-- load the https module
	local socket = require "socket"
	local https = require("https")
	if not sURL then sURL="http://www.google.de/search?q=myScite&oq=myScite" end
	local body, code, status= https.request(sURL)
	props["fetchHTTP.code"]=code
	props["fetchHTTP.status"]=status
	props["fetchHTTP.body"]=body
	return body
end
--
-- quickCheck a files CRC32 Hash 
--
if C32==nil then err,C32 = pcall( require,"crc32")  end
function fileHash(fileName)
	if type(C32)~="table" then return end
	local CRChash=""
	if fileName~="" then
	
		local crc32=C32.crc32
		local crccalc = C32.newcrc32()
		local crccalc_mt = getmetatable(crccalc)

		-- crc32 was made for eating strings...:)
		local file,err = assert(io.open (fileName, "r"))
		if err then return end
		while true do
			local bytes = file:read(8192)
			if not bytes then break end
			crccalc:update(bytes)
		end	
		file:close()
		CRChash=crccalc:tohex()
		crccalc.reset(crccalc)-- reset to zero
		file=nil crccalc_mt=nil crccalc=nil crc32=nil C32=nil
	end

	return CRChash
end
--
-- returns the size of a given file.
--
function file_size (filePath)
	if filePath ==""  then return end
	local attr=nil size=nil

	if lfs==nil then err,lfs = pcall(require,"lfs")  end
	if type(lfs) == "table" then attr,err=lfs.attributes (filePath)  end
	if type(attr) == "table" then size= attr.size return size end

	local myFile,err=io.open(filePath,"r")
	if not err then -- todo handle filePath containing Unicode chars 
		size = myFile:seek("end")  
		myFile:close() 
	end

	return size or 0
end
--
-- ensure creation of homeDir/tmpDir
--
function init_scite_dir()
	local home
	if lfs==nil then err,lfs = pcall(require,"lfs")  end
	if type(lfs) ~= "table" then return false end
	if props["PLAT_WIN"]=="1" then
		home=props["USERPROFILE"]
	else
		home=props["HOME"]
	end	
	res= lfs.mkdir(home.."\\scite")
	res= lfs.attributes(home.."\\scite")
	if res==nil then return false end	
	res= lfs.mkdir(props["TMP"].."\\scite")
	res= lfs.attributes(props["TMP"].."\\scite")
	if res==nil then return false end
	return true	
end
--
-- compare SciLexerHash and Release Info with github Repositories readme.
-- signal when theres a new Version available.
--
function checkUpdates()
local curVersion
local checkInterval=4
local lastChecked=0
	init_scite_dir()
	lastChanged= lfs.attributes(props["TMP"].."\\SciTE\\scite_versions.txt","modification")
		if lastChanged ~= nil then
			-- create a calculateable datestring like 20190104
			timeStamp=os.date('%Y%m%d', os.time())
			lastChanged=os.date('%Y%m%d', lastChanged)
			lastChecked=timeStamp -lastChanged
			--print(timeStamp.." "..lastChanged.." "..lastChecked)
		else
			lastChecked=checkInterval
		end
		if lastChecked>=checkInterval then
			-- download version Info from githubs readme.md
			local pipe=scite_Popen("cscript.exe \""..props["SciteUserHome"].."\\Installer\\scite_getVersionInfo.vbs\"" )
			local tmp= pipe:read('*a') -- synchronous -waits for the Command to complete
			if not tmp:match("STATUS:OK") then return end
			for line in io.lines(props["TMP"].."\\SciTE\\scite_versions.txt") do
				if line:match(props["SciLexerHash"]) then curVersion=line end
				if line:match(props["Release"]) then curVersion=line end
			end
			if curVersion~=nil and curVersion:match('.$')=="1" then
				print("An Update for your Version has been found.")
				print ("Please see https://sourceforge.net/projects/scite-webdev/files/releases/")
			--else if curVersion:match('.$')=="0" then print("No Updates available.") end
			-- update timestamp, so the next version check will take place at checkInterval.
				local pipe=scite_Popen("copy /B "..props["TMP"].."\\SciTE\\scite_versions.txt+,," )
			end
			pipe=nil
		end
end