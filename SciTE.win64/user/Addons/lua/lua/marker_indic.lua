-- marker_indic.lua
-- Marker, Indicator and Breakpoint Management Functions
--
scite_require 'classold.lua'
local append = table.insert

-- indicators --
-- INDIC_PLAIN   Underlined with a single, straight line.
-- INDIC_SQUIGGLE  	A squiggly underline.
-- INDIC_TT  A line of small T shapes.
-- INDIC_DIAGONAL  	Diagonal hatching.
-- INDIC_STRIKE  	Strike out.
-- INDIC_HIDDEN	An indicator with no visual effect.
-- INDIC_BOX 	A rectangle around the text.

local indicator_masks = {[0] = INDIC0_MASK, [1] = INDIC1_MASK, [2] = INDIC2_MASK}

local function indicator_mask(ind)
	return indicator_masks[ind]
end

-- this is the default situation: first 5 bits are for lexical styling
local style_mask = 31

-- get the lexical style at position p, without indicator bits!
function style_at(p)
	return math.mod(editor.StyleAt[p],32)
end

-- define a given indicator's type and foreground colour
Indicator = class(function(self,which,typ,colour)
	editor.IndicStyle[which] = typ
	if colour then
		editor.IndicFore[which] = colour_parse(colour)
	end
	self.ind = which
end)

-- set the given indicator ind between pos and endp inclusive
-- (the val arg is only used by indicator_clear)
function Indicator:set(pos,endp,val)
    local es = editor.EndStyled
	local mask = indicator_mask(self.ind)
	if not val then
		val = mask
	end
    editor:StartStyling(pos,mask)
    editor:SetStyling(endp-pos,val)
    editor:StartStyling(es,style_mask)
end

-- clear an indicator ind between pos and endp
function Indicator:clear(ind,pos,endp)
	self:set(pos,endp,0)
end

-- find the next position which has indicator ind
-- (won't handle overlapping indicators!)
function Indicator:find(pos)
	if not pos then pos = editor.CurrentPos end
	local endp = editor.Length
	local mask = indicator_mask(self.ind)
	while pos ~= endp do
		local style = editor.StyleAt[pos]
		if style > style_mask then -- there are indicators!
			-- but is the particular bit set?
			local diff = style - mask
			if diff >= 0 and diff < mask then
				return pos
			end
		end
		pos = pos + 1
	end
end

-- markers --

Marker = class(function(self,idx,line,file)
	buffer = scite_CurrentFile()
	if not file then file = buffer end
	self.idx = idx
	self.file = file
	self.line = line
	if file == buffer then
		self:create()
	else
		self.state = 'waiting'
	end
end)

function Marker:create()
	self.handle = editor:MarkerAdd(self.line-1,self.idx)
	if self.handle == -1 then
		self.state = 'dud'
		if self.type then self:cannot_create(self.file,self.line) end
	else
		self.state = 'created'
	end
end

function Marker:delete()
	if self.file ~= scite_CurrentFile() then -- not the correct buffer!
		self.state = 'expired'
	else
		editor:MarkerDelete(self.line-1,self.idx)
		if self.type then self.type:remove(self) end
	end
end

function Marker:gotoLn(centre)
	editor:GotoLine(self.line-1)
	if centre then center_line() end
end

function Marker:update_line()
	self.line = editor:MarkerLineFromHandle(self.handle)+1
end

MarkerType = class(function(self,idx,typ,fore,back)
	if typ then editor:MarkerDefine(idx,typ) end
	if fore then editor:MarkerSetFore(idx,colour_parse(fore)) end
	--adapted for Scite3.6.2
 	if back then editor.MarkerBack[idx] = colour_parse(back)end
	self.idx = idx
	self.markers = create_list()
	-- there may be 'expired' markers which need to finally die!
	scite_OnSwitchFile(function(f)
		local ls = create_list()
		for m in self:for_file() do
			if m.state == 'expired' or m.state == 'dud' then
				ls:append(m)
			end
			if m.state == 'waiting' then
				m:create()
			end
		end
		for m in ls:iter() do
			m:delete()
		end
	end)
	-- when a file is saved, we update any markers associated with it.
	scite_OnSave(function(f)
		local changed = false
		for m in self:for_file() do
			local lline = m.line
			m:update_line()
			changed = changed or lline ~= m.line
		end
		if changed then
			self:has_changed('moved')
		end
	end)
end)

function MarkerType:has_changed(how)
	if self.on_changed then
		self:on_changed(how)
	end
end

function MarkerType:cannot_create(file,line)
	print('error:',file,line)
end

function MarkerType:create(line,file)
	local m = Marker(self.idx,line,file)
	self.markers:append(m)
	m.type = self
	self:has_changed('create')
	return m
end

function MarkerType:remove(marker)
	if self.markers:remove(marker) then
		self:has_changed('remove')
	end
end

-- return an iterator for all markers defined in this file
-- (see PiL, 7.1)
function MarkerType:for_file(fname)
	if not fname then fname = scite_CurrentFile() end
	local i = 0
    local n = #self.markers --fix lua5.3.4
	local t = self.markers
--~ 	print(n,t)
    return function ()
               i = i + 1
               while i <= n do
--~ 					print (i,t[i].line)
					if t[i].file == fname then
						return t[i]
					else
						i = i + 1
					end
				end
             end
end

function MarkerType:iter()
	return self.markers:iter()
end

function MarkerType:dump()
	for m in self:iter() do
		print(m.line,m.file)
	end
end

Bookmark = MarkerType(1)

g = {} -- for globals that don't go away ;)

-- get the next line following the marker idx
-- from the specified line (optional)
function MarkerType:next(line)
	if not line then line = current_line() end
	local mask = math.pow(2,self.idx)
	return editor:MarkerNext(line,mask)+1
end

------ Marker management -------
local active_cursor_idx = 5
local signalled_cursor_idx = 6
local breakpoint_idx = 7
local active_cursor = nil
local signalled_cursor = nil
local breakpoint = nil
local last_marker = nil
local initialized = false

local function init_breakpoints()
	if not initialized then
		active_cursor = MarkerType(active_cursor_idx,SC_MARK_BACKGROUND,nil,props['stdcolor.active'])
		signalled_cursor = MarkerType(signalled_cursor_idx,SC_MARK_BACKGROUND,nil,props['stdcolor.error'])
		breakpoint = MarkerType(breakpoint_idx,SC_MARK_ARROW,nil,props['stdcolor.breakpoint'])
		initialized = true
	end
end

function Breakpoints()
	init_breakpoints()
	return breakpoint:iter()
end

function RemoveLastMarker(do_remove)
	if last_marker then
		last_marker:delete()
	end
	if do_remove then
		last_marker = nil
	end
end

function OpenAtPos(fname,lineno,how)
	init_breakpoints()
	RemoveLastMarker(false)
	if not last_marker or (last_marker and fname ~= last_marker.file) then
		scite.Open(fname)
	end
	if how == 'active' then
		last_marker = active_cursor:create(lineno)
	elseif how == 'error' then
		last_marker = signalled_cursor:create(lineno)
	else
		last_marker = nil
	end
	if last_marker then
		last_marker:gotoL()
	else
		editor:GotoLine(lineno-1)
	end
end

function SetBreakMarker(line)
	init_breakpoints()
	return breakpoint:create(line)
end
