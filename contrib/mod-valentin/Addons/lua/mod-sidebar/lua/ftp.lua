--!encoding=utf-8

--****************************************************************************
-- @file      FTP CLASS
-- @author    Valentin Schmidt
-- @version   0.1
--
-- Simple FTP client based on cURL
--
-- @todo Add SFTP support - requires compiling a SFTP enhanced version of curl.dll
--****************************************************************************

require 'curl'
require 'io'
require 'scite'

-- Meta class
Ftp = {
  pProtocol=nil,
  pHost=nil,
  pUser=nil,
  pPass=nil,
  pPort=nil,
  pCh=nil,
  pData=nil
}

----------------------------------------
-- Derived class method new
----------------------------------------
function Ftp:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

----------------------------------------
-- Set FTP host
-- @param {string} protocol
-- @param {string} host
-- @param {string} user
-- @param {string} pass
-- @param {string} [pass]
----------------------------------------
function Ftp:setHost (protocol, host, user, pass, port)
  self.pProtocol = protocol
  self.pHost = host
  self.pUser = user
  self.pPass = pass
  self.pPort = port
end

----------------------------------------
-- Gets directory listing
-- @param {string} remoteDir
-- @return {string}
----------------------------------------
function Ftp:list (remoteDir)

  local url = self.pProtocol.."://"..self.pHost --..port..remoteDir

  if self.pPort~=nil then url = url..":"..self.pPort end
  if remoteDir:sub(1,1)~="/" then url = url.."/" end
  url = url..remoteDir
  if remoteDir:sub(-1)~="/" then url = url.."/" end
  
scite.put(url)

  -- get a CURL handle
  self.pCh = curl.easy_init ()

  -- specify options
  self.pCh:setopt(curl.OPT_URL, url)
  if self.pPass~=nil then
    self.pCh:setopt(curl.OPT_USERPWD, self.pUser..":"..self.pPass)
  end

  local data = {}
  self.pCh:setopt(curl.OPT_WRITEFUNCTION, function(str, len)
    table.insert(data, str)
    return len, nil
  end)

  -- run
  local res, err = self.pCh:perform() --  number,errorstring. number not zero means an error.

  if res~=0 then return false, err end
  return true, self:_parseListing(table.concat(data))
end

----------------------------------------
-- Downloads remote file
-- remoteFile, localFile: either absolute pathes, or relative to moviepath
-- @param {string} remoteFile
-- @param {string} localFile
----------------------------------------
function Ftp:download (remoteFile, localFile)

  local port
  if self.pPort==nil then port = ""
  else port = ":"..self.pPort end

  if remoteFile:sub(1,1)~="/" then remoteFile = "/"..remoteFile end

  local url = self.pProtocol.."://"..self.pHost..port..remoteFile
scite.put(url)

  -- get a CURL handle
  self.pCh = curl.easy_init()

  -- specify options
  self.pCh:setopt(curl.OPT_URL, url)
  if self.pPass~=nil then
    self.pCh:setopt(curl.OPT_USERPWD, self.pUser..":"..self.pPass)
  end

	-- write function
  local f = io.open(localFile, "wb")
  self.pCh:setopt(curl.OPT_WRITEFUNCTION, function(str, len)
    f:write(str)
    return len,nil
  end)

  -- run
  local res, err = self.pCh:perform()

  f:close() 

  return res==0, err
end

----------------------------------------
-- Uploads local file
-- remoteFile, localFile: either absolute pathes, or relative to moviepath
-- @param {string} localFile
-- @param {string} remoteFile
----------------------------------------
function Ftp:upload (localFile, remoteFile)

  local port
  if self.pPort==nil then port = ""
  else port = ":"..self.pPort end

  if remoteFile:sub(1,1)~="/" then remoteFile = "/"..remoteFile end

  local url = self.pProtocol.."://"..self.pHost..port..remoteFile

  -- get a CURL handle
  self.pCh = curl.easy_init()

  -- specify options
  self.pCh:setopt(curl.OPT_URL, url)
  if self.pPass~=nil then
    self.pCh:setopt(curl.OPT_USERPWD, self.pUser..":"..self.pPass)
  end
  
  self.pCh:setopt(curl.OPT_UPLOAD, 1) -- ???
  --self.pCh:setopt(curl.OPT_INFILESIZE, $.file.size(localFile)) -- optional

  -- read function
  local f = io.open(localFile, "rb")
  self.pCh:setopt(curl.OPT_READFUNCTION, function(n)
    local str = f:read(n)
    if str==nil then return 0, "" end
    return #str,str -- binary safe?
  end)

  -- run
  local res, err = self.pCh:perform()

  f:close ()

  return res==0, err
end

----------------------------------------
-- Parses "ls" listing
-- @param {string} listing
-- @return {table}, {table}
----------------------------------------
function Ftp:_parseListing (str)
--scite.put("_parseListing")

  local files = {}
  local folders = {}
  local info

  --lines = $.regex.match("[^\r\n]+", str)

--  local sep, fields = sep or ":", {}
--  local pattern = string.format("([^%s]+)", sep)
--  self:gsub(pattern, function(c) fields[#fields+1] = c end)
--  return fields

  str:gsub("([^\r\n]+)", function(l)
    info = self:_parseListingLine(l)
    if info["name"]~="." and info["name"]~=".." then
      if info["type"]=="file" then files[#files+1] = info["name"]
      else folders[#folders+1] = info["name"] end
    end
  end)

--  repeat with l in lines
--    info = me._parseListingLine(l)
--    if info["name"]="." or info["name"]=".." then next repeat
--    if info["type"]="file" then
--      files.add(info["name"])
--    else
--      folders.add(info["name"])
--    end if
--  end repeat

  return folders, files
end

----------------------------------------
--
----------------------------------------
function Ftp:_parseListingLine (str)
--scite.put("_parseListingLine "..str)

  local info = {}
  --chunks = $.regex.split("\s+", str)

--  info["rights"] = chunks[1]
--  info["number"] = chunks[2]
--  info["user"] = chunks[3]
--  info["group"] = chunks[4]
--  info["size"] = chunks[5]
--  info["month"] = chunks[6]
--  info["day"] = chunks[7]
--  info["time"] = chunks[8]

  --iterate over all the words from string s,
  local chunks = {}
  --for w in string.gmatch(str, "%a+") do chunks[#chunks+1] = w end
  for w in string.gmatch(str, "([^%s]+)") do chunks[#chunks+1] = w end

  --self:gsub(pattern, function(c) fields[#fields+1] = c end)

  if chunks[1]:sub(1,1)=="d" then
    info["type"]="folder"
  else
    info["type"]="file"
  end

  -- get name
  info["name"] = chunks[9]
  if #chunks>9 then info["name"] = info["name"]..table.concat(chunks, " ", 10) end

  return info
end
