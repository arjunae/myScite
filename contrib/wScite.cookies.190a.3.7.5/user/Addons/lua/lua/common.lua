-- COMMON.lua -- 

local sub = string.sub
local append = table.insert
local find = string.find
if lpeg==nil then err,lpeg = pcall( require,"lpeg")  end

------------------------------------------
-- Custom Common Functions --
------------------------------------------

--------------------------
-- check if current Docs charset is Unicode using lpeg regexp 
-- if found, switches Current docs mode to (UTF-8) 
--------------------------
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

----------------------------------
-- Enables above UTF-8 checking via property 
----------------------------------
function DetectUTF8()
	if props["editor.detect.utf8"] == "1" then
		if editor.CodePage ~= SC_CP_UTF8 then
			CheckUTF8()
		end
	end
end

--------------------------
-- quickCheck a files CRC32 Hash 
--------------------------
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

-- check SciLexer once per session and inform the User if its a nonStock Version.

local SLHash
if not SLHash then SLHash=fileHash( props["SciteDefaultHome"].."\\SciLexer.dll" )  
	if SLHash and SLHash~=props["SciLexerHash"] then print("common.lua: You are using a modified SciLexer.dll with CRC32 Hash: "..SLHash) end
end

--------------------------
-- returns the size of a given file.
--------------------------
function file_size (filePath)
	if filePath ==""  then return end
	local attr=nil size=nil

	if lfs==nil then err,lfs = pcall( require,"lfs")  end
	if type(lfs) == "table" then attr,err=lfs.attributes (filePath)  end
	if type(attr) == "table" then size= attr.size return size end

	local myFile,err=io.open(filePath,"r")
	if not err then -- todo handle filePath containing Unicode chars 
		size = myFile:seek("end")  
		myFile:close() 
	end

	return size or 0
end

 --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 --line information functions --
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

-- what is the word directly behind the cursor?
-- returns the word and its position.
function word_at_cursor()
	local pos = editor.CurrentPos
	local line_start = start_line_position()
	-- look backwards to find the first non-word character!
	local p1,p2 = editor:findtext(NOT_WORD_PATTERN,SCFIND_REGEXP,pos,line_start)
	if p1 then
		return editor:textrange(p2,pos),p2
	end
end

-- this centers the cursor position
-- easy enough to make it optional!
function center_line(line)
	if not line then line = current_line() end
	local top = editor.FirstVisibleLine
	local middle = top + editor.LinesOnScreen/2
	editor:LineScroll(0,line - middle)
end


-- allows you to use standard HTML '#RRGGBB' colours;
function colour_parse(str)
	-- Wo for nil value
	if str == nil then str ="#AAFFAA" end
	return tonumber(sub(str,6,7)..sub(str,4,5)..sub(str,2,4),16)
end


function rtrim(s)
    return string.gsub(s,'%s*$','')
end

--------------------------
-- converts a colour to windows format, 
-- brings up guis colour dialouge
-- change the current doc to that colour
--------------------------
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

--------------------------
-- Convert a Documents encoding from and to UTF8
--------------------------
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

------------------------------------------
-- EditorMarkText
------------------------------------------
function EditorMarkText(start, length, style_number)
	local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
	scite.SendEditor(SCI_SETINDICATORCURRENT, style_number)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
	scite.SendEditor(SCI_SETINDICATORCURRENT, current_mark_number)
end

------------------------------------------
-- EditorClearMarks
------------------------------------------
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

------------------------------------------
-- Get Start Word
------------------------------------------
function GetStartWord()
	local current_pos = editor.CurrentPos
	return editor:textrange(editor:WordStartPosition(current_pos, true),current_pos)
end

------------------------------------------
-- os_copy
------------------------------------------
function os_copy(source_path,dest_path)
	return with_open_file(source_path,"rb") (function(source)
		return with_open_file(dest_path,"wb") (function(dest)
			assert(dest:write(assert(source:read("*a"))))
			return true
		end)
	end)
end

------------------------------------------
-- ifnil
------------------------------------------
function ifnil(prop, def)
	local val = props[prop]
	if val == nil or val == '' then
		return def
	else
		return val
	end
end

------------------------------------------
-- Translate color from RGB to win
------------------------------------------
local function encodeRGB2WIN(color)
	if color == nil then return nil end
	if string.sub(color,1,1)=="#" and string.len(color)>6 then
		return tonumber(string.sub(color,6,7)..string.sub(color,4,5)..string.sub(color,2,3), 16)
	else
		return color
	end
end

------------------------------------------
-- Translate INDIC_*
------------------------------------------
local function GetStyle(mark_string)
	local mark_style_table = {
		plain    = INDIC_PLAIN,    squiggle = INDIC_SQUIGGLE,
		tt       = INDIC_TT,       diagonal = INDIC_DIAGONAL,
		strike   = INDIC_STRIKE,   hidden   = INDIC_HIDDEN,
		roundbox = INDIC_ROUNDBOX, box      = INDIC_BOX
	}
	return mark_style_table[mark_string]
end

------------------------------------------
-- Init Mark Style
------------------------------------------
local function InitMarkStyle(mark_number, mark_style, color, alpha)
	editor.IndicStyle[mark_number] = mark_style
	editor.IndicFore[mark_number]  = encodeRGB2WIN(color)
	editor.IndicAlpha[mark_number] = alpha
	editor.IndicUnder[mark_number] = true
end

------------------------------------------
-- Parse Mark Style From Prop String
------------------------------------------
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
