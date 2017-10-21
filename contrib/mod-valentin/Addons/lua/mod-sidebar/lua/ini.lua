--require 'scite'

do

-- trim a string
local function trim(s)
	assert(s ~= nil, "String can't be nil")
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- Load an INI file
local function _load(path)
	local f = io.open(path, "r")
	if f==nil then return end
	
	local tab = {}
	local keys = {}
	
	local line = ""
	local i
	local currentTag = nil
	local pos = 0

	local prop
	local val
		
	while true do
		line = f:read("*line")
		if line==nil then break end
		if line ~= "" and line:sub(1,1)~=";" then
			line = trim(line)
			if line:sub(1, 1) == "[" and line:sub(line:len(), line:len()) == "]" then
				currentTag = trim(line:sub(2, line:len()-1))
				tab[currentTag] = {}
				keys[currentTag] = {}
			else
				pos = line:find("=")
				if pos == nil then error("Bad INI file structure") end
				prop = trim(line:sub(1, pos-1))
				val = trim(line:sub(pos+1, line:len()))
				if prop=="" then 
					table.insert(tab[currentTag], val)
				else
					tab[currentTag][prop] = val
				end
				table.insert(keys[currentTag], prop)
			end
		end
	end
		
	f:close()
	return tab, keys
end

----------------------------------------
-- ini lib interface
----------------------------------------
ini = {
	load = _load
}

end