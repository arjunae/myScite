require 'io'
--require 'scite'


-- PRIVATE FUNCTIONS

local function _findLast(filePath) -- find index of last / or \ in string
  local lastOffset = nil
  local offset = nil
  repeat
    offset = string.find(filePath, "\\") or string.find(filePath, "/")
    if offset then
      lastOffset = (lastOffset or 0) + offset
      filePath = string.sub(filePath, offset + 1)
    end
  until not offset
  return lastOffset
end

-- GLOBAL FUNCTIONS

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function string:starts(str)
	return self:sub(1, #str)==str
end

----------------------------------------
--
----------------------------------------
function string:unescape()
  return self:gsub("%%(%x%x)", function(x)
	  return string.char(tonumber(x, 16))
	end)
end

function join(tab, sep)
	return table.concat(tab, sep) --> "a,b,c"
end

function fileExists(fn)
	local f=io.open(fn,"r")
	if f~=nil then io.close(f) return true else return false end
end

function getFileType(fn)
	local tmp = fn:split(".")
	return tmp[#tmp]
end

function getWinPath(fn)
	return fn:gsub("/", "\\")
end
  
----------------------------------------
-- return the path part of the currently executing file
----------------------------------------
function getPath(filePath)
	local start=1
	if filePath:sub(1,1)=="@" then start=2 end
  local offset = _findLast(filePath)
  if offset ~= nil then
    -- remove the @ at the front up to just before the path separator
    filePath = filePath:sub(start, offset - 1)
  else
    filePath = "."
  end
  return filePath.."\\"
end
