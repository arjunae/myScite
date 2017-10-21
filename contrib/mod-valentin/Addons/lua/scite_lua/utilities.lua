-- ###################################################################
-- Forces UTF-8 Encoding also for Non-BOM UTF-8 files
-- (c) Valentin Schmidt 2016

package.path = package.path..';Addons/lua/mod-sidebar/lua/?.lua'
require 'bit'

----------------------------------------
-- Checks if bytes of current file are a valid UTF-8 sequence
-- Notice: since ASCII is a UTF-8 subset, function also returns true for pure ASCII data
-- @return {bool}
----------------------------------------
function isUtf8 ()
	local code = editor:GetText()
	local len = #code
	local ord
	local n
	local i = 1
	while i<=len do
		ord = code:byte(i)
		if (ord > 127) then
			if (bit.band(ord,224)==192 and ord>193) then n = 1 -- 110bbbbb (C0-C1)
			elseif (bit.band(ord,240)==224) then n = 2 -- 1110bbbb
			elseif (bit.band(ord,248)==240 and ord<245) then n = 3 -- 11110bbb (F5-FF)
			else return false end -- invalid UTF-8 sequence
	    for c = 1, n, 1 do
	    	i = i+1
	    	if i>len then return false end -- invalid UTF-8 sequence
	      if (bit.band(code:byte(i),192)~=128) then return false end -- invalid UTF-8 sequence
	    end
		end
		i = i+1
	end
	return true -- no invalid UTF-8 sequence found
end

----------------------------------------
-- Forces UTF-8 Encoding also for Non-BOM UTF-8 files, but doesn't change Encoding for e.g. Latin-1 files,
-- so both are displayed correctly in SciTE. 
-- Requires setting "code.page=0" (=automatic) in SciTEGlobal.properties
----------------------------------------
scite_OnOpen(function(fn)
	if editor.CodePage~=65001 and isUtf8() then		
		scite.MenuCommand(154)
	end
end)

-- ###################################################################
-- Sort selected text
-- (c) Valentin Schmidt 2016

----------------------------------------
-- Returns an iterator function that, each time it is called, returns the next
-- captures from pattern over string s
----------------------------------------
local function getLines(s, eol)	
	if not eol then eol = '\n' end
	if s:sub(-string.len(eol))~=eol then s=s..eol end
	if eol=='\n' then
		return s:gmatch("(.-)\n")
	elseif eol=='\r' then
		return s:gmatch("(.-)\r")
	else
		return s:gmatch("(.-)\r\n")
	end
end

function sortSelection()
  local sel = editor:GetSelText()
  if #sel == 0 then return end

	local eol
	local eolFlag
	
	-- get editor's current EOL (0=CRLF, 1=CR, 2=LF)
	if editor.EOLMode==0 then
		eol = '\r\n'
		eolFlag = string.match(sel, "\n$")
	elseif editor.EOLMode==1 then
		eol = '\r'
		eolFlag = string.match(sel, "\r$")
	else
		eol = '\n'
		eolFlag = string.match(sel, "\r\n$")
	end
		
	-- get table of lines
	local t = {}
	for line in getLines(sel, eol) do
		table.insert (t, line)
	end
		  
	-- sort case sensitive
  --table.sort(t)
  
  -- sort case-insensitive
  table.sort(t, function(t1,t2) return (t1:lower() < t2:lower() ) end )
  
  local out = table.concat(t, eol)
  if eolFlag then out = out..eol end
  
  editor:ReplaceSel(out)
end

scite_Command {
  'Sort Selection|sortSelection|Alt+Shift+S',
}

-- ###################################################################
-- fix EOL according to current editor's setting/detection
-- (c) Valentin Schmidt 2016

function fixEol()
		
	-- Note that \r and \n are never matched because in Scintilla, regular expression 
	-- searches are made line per line (stripped of end-of-line chars). 
	
	if editor.EOLMode==0 then -- CRLF mode
		local code = editor:GetText()
		local matches, m1, m2, m3, m4, tmp
		
		-- replace \n\n with \r\n\r\n
		code, m1 = string.gsub(code, "\n\n", '\r\n\r\n')
		--print("Matches LF LF", m1)
		
		-- replace orphan \n with \r\n
		tmp, m2 = string.gsub(' '..code, "([^\r])[\n]", '%1\r\n')
		if m2>0 then code = tmp.sub(tmp,2) end
		--print("Matches LF", m2)
		
		-- replace \r\r with \r\n\r\n
		code, m3 = string.gsub(code, "\r\r", '\r\n\r\n')
		--print("Matches CR CR", m3)
		
		-- replace orphan \r with \r\n
		tmp, m4 = string.gsub(code..' ', "[\r]([^\n])", '\r\n%1')
		if m4>0 then code = tmp.sub(tmp,1,-2) end
		--print("Matches CR", m4)
		
		if (m1+m2+m3+m4)>0 then editor:SetText(code) end

	elseif editor.EOLMode==1 then -- CR mode		
		-- remove \n
	  for m in editor:match('\n', 0) do
	    m:replace('\r')
	  end
	  
	else -- LF mode
		-- remove \r
	  for m in editor:match('\r', 0) do
	    m:replace('\n')
	  end
	end

end

scite_Command {
  'Fix EOL|fixEol|Alt+Shift+L'
}

-- ###################################################################
-- Insert date string at current position
-- 2013.03.31 by lee.sheen at gmail dot com

function InsertDate ()
  local date_string = os.date("%Y-%m-%d %H:%M:%S")
  -- Tags used by os.date:
  --   %a abbreviated weekday name (e.g., Wed)
  --   %A full weekday name (e.g., Wednesday)
  --   %b abbreviated month name (e.g., Sep)
  --   %B full month name (e.g., September)
  --   %c date and time (e.g., 09/16/98 23:48:10)
  --   %d day of the month (16) [01-31]
  --   %H hour, using a 24-hour clock (23) [00-23]
  --   %I hour, using a 12-hour clock (11) [01-12]
  --   %M minute (48) [00-59]
  --   %m month (09) [01-12]
  --   %p either "am" or "pm" (pm)
  --   %S second (10) [00-61]
  --   %w weekday (3) [0-6 = Sunday-Saturday]
  --   %x date (e.g., 09/16/98)
  --   %X time (e.g., 23:48:10)
  --   %Y full year (1998)
  --   %y two-digit year (98) [00-99]
  --   %% the character '%'

  editor:AddText(date_string)
end

scite_Command {
  'Insert Date|InsertDate|Alt+Shift+D',
}

-- ###################################################################
-- SciteConvertDecHex
-- Convert the selected text to decimal or hex
-- 2013.04.06 by lee.sheen at gmail dot com

local function isHexString (s)
  local header = string.sub(s, 1, 2)
  if "0x" == header or "0X" == header then
    return true
  else
    return false
  end
end

function ConvertDecHex ()
  local current_selected_text, current_selected_length = editor:GetSelText()
  local converted_number = tonumber(current_selected_text)
  if  not (converted_number == nil) then
    local converted_text = nil
    if isHexString(current_selected_text) then
      converted_text = tostring(converted_number)
    else
      converted_text = string.format("0x%X", converted_number)
    end
    editor:ReplaceSel(converted_text)
  end
end

scite_Command {
  'Convert Dec/Hex|ConvertDecHex|Alt+Shift+C',
}