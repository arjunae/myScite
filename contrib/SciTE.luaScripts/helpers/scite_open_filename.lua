------------------------------------------------------------------------
-- Lua-based OpenFilename (Ctrl+Shift+O) replacement for SciTE
------------------------------------------------------------------------
-- Revised 20070329, Kein-Hong Man <khman@users.sf.net>
-- This script is hereby placed into PUBLIC DOMAIN.
------------------------------------------------------------------------
-- Limitations compared to original OpenFilename function:
-- * For PLAT_WIN, does not support opening of http:, ftp: etc.
-- * "open.suffix.{filepattern}" and "openpath.{filepattern}" properties
--   are not supported, instead we have custom handlers.
-- * CTAGS not supported. See http://lua-users.org/wiki/SciteTags for
--   a Lua-based solution.
------------------------------------------------------------------------
-- 20070329 fixed bug in lookupExt() comparing extensions
------------------------------------------------------------------------
function OpenFilename()
  ---------------------------------------------------------------
  -- configuration stuff, please customize to suit your system
  -- you can also add other search paths here, e.g. the directory
  -- of Scintilla include files, if you work on Scintilla a lot
  ---------------------------------------------------------------
  local perlPaths = {                           -- perl lib root
    --"/usr/lib/perl5/5.8.0",
    "c:/perl/lib",
  }
  local pythonPaths = {                         -- python lib root
    --"/usr/lib/python2.2",
    "", --(current dir)
    "c:/Python25/lib",
    "c:/Python25/lib/plat-win",
    "c:/Python25/lib/lib-tk",
    "c:/Python25/lib/site-packages",
  }
  local cPaths = {                              -- c/c++ lib root
    --"/usr/include",
    "d:/mingw/include",
    "d:/mingw/include/c++/3.4.2",
    "d:/msys/1.0/include",
    --"d:/cygwin/usr/include",
    --"d:/cygwin/usr/include/c++/3.3.3",
  }
  local MAX_PATH = 260          -- not really checked...
  local NonFilenameChar = "[\t\n\r \"%$%%'%*,;<>%?%[%]%^`{|}]"
  ---------------------------------------------------------------
  -- support functions
  ---------------------------------------------------------------
  -- force CharAt values to 0-255, convert to string
  local function CharAt(pos)
    local c = editor.CharAt[pos] or 32
    if c < 0 then c = c + 256 end
    return string.char(c)
  end
  -- check if file exists
  local function FileExists(name)
    local f = io.open(name)
    if f then f:close() return true end
    return false
  end
  -- check if path is absolute
  local function IsAbsolute(name)
    if not name or name == "" then return end
    local f = string.sub(name, 1, 1)
    if f == "/" or f == "\\"    -- unix/win32
       or (string.sub(name, 2, 2) == ":" and string.sub(name, 3, 3) ~= ":") then
       -- must match :[^:] due to use of :: in perl
      return true
    end
    return false
  end
  ---------------------------------------------------------------
  -- range selection and extension
  ---------------------------------------------------------------
  local selBeg, selEnd = editor.Anchor, editor.CurrentPos
  if selBeg > selEnd then
    -- explicit selection, swap index
    selBeg, selEnd = selEnd, selBeg
  elseif selBeg == selEnd then
    -- no selection; extend caret left & right into a range
    if selBeg > 0 then
      while not string.find(CharAt(selBeg - 1), NonFilenameChar) do
        selBeg = selBeg - 1
      end
    end
    while not string.find(CharAt(selEnd), NonFilenameChar) do
      selEnd = selEnd + 1
    end
    -- beware, unlike RangeExtendAndGrab, no CRLF chomping is performed, needed?
  end
  if selEnd - selBeg <= 0 then return end
  -- grab delimiter pair for later testing
  local delimL, delimR = CharAt(selBeg - 1), CharAt(selEnd)
  -- target file name and extension
  local fname = editor:textrange(selBeg, selEnd)
  if string.len(fname) >= MAX_PATH then
    fname = string.sub(fname, 1, MAXPATH - 1)
  end
  local _, _, fext = string.find(fname, "%.([_%w]*)$")
  fext = fext or ""
  local thisLine = editor:LineFromPosition(selBeg)
  -- prefix, start of line to left of possible filename
  local preBeg, preEnd = editor:PositionFromLine(thisLine), selBeg - 1
  if preEnd < preBeg then preEnd = preBeg end
  local preTxt = editor:textrange(preBeg, preEnd)
  -- current file info
  local thisExt = props["FileExt"] or ""
  local thisPath = props["FileDir"] or ""
  thisPath = string.gsub(thisPath, "%\\", "/")
  ---------------------------------------------------------------
  -- grab line number spec (see test sequences further below):
  ---------------------------------------------------------------
  local lnum = nil
  local lnspec = { "%((%d+)%)", ":(%d+):", }
  for _, regexp in ipairs(lnspec) do
    local x, _, ln = string.find(fname, regexp)
    if x and x > 1 then
      lnum = tonumber(ln)
      fname = string.sub(fname, 1, x - 1)
      break
    end
  end
  ---------------------------------------------------------------
  -- C++ header detect (needed for C++ headers which do not have
  -- an extension and is not currently recognized as C++ by SciTE)
  ---------------------------------------------------------------
  for _, path in ipairs(cPaths) do
    if string.find(string.lower(thisPath), string.lower(path), 1, 1) then
      thisExt = "h"             -- force recognition as header file
    end
  end
  ---------------------------------------------------------------
  -- extended handlers for particular languages
  ---------------------------------------------------------------
  -- custom handler lookups
  local customjobs = {
    -- <SciTE property> = <function name>
    ["file.patterns.props"] = "props",
    ["file.patterns.cpp"] = "cpp",
    ["file.patterns.rc"] = "cpp",
    ["file.patterns.idl"] = "cpp",
    ["file.patterns.perl"] = "perl",
    ["file.patterns.py"] = "python",
  }
  -- custom handlers; entered only if fname isn't an absolute path
  -- style is not checked (should work on code that is commented out)
  local jobfuncs = {
    ---------------------------------------------------------
    props = function(name)
      -- support for "import foo" lines in property files
      if thisExt == "properties"
         and not string.find(name, ".", 1, 1)
         and string.find(preTxt, "import%s*") then
        name = name..".properties"
      end
      return name
    end,
    ---------------------------------------------------------
    perl = function(name)
      if string.find(preTxt, "use%s*")
         or string.find(preTxt, "require%s*")
         or string.find(preTxt, "[dn]o%s*") then
        -- no support for old-style package delimiter (')!
        for _, path in ipairs(perlPaths) do
          local fnew = path.."/"..string.gsub(name, "::", "/")
          if not string.find(fnew, "%.") then fnew = fnew..".pm" end
          if FileExists(fnew) then return fnew end
        end
      end
      return name
    end,
    ---------------------------------------------------------
    python = function(name)
      if string.find(preTxt, "^%s*import%s*")
         or string.find(preTxt, "^%s*from%s*") then
        for _, path in ipairs(pythonPaths) do
          local fnew = path
          if path == "" or path == "." then fnew = thisPath end
          fnew = fnew.."/"..string.gsub(name, "%.", "/")..".py"
          if FileExists(fnew) then return fnew end
        end
      end
      return name
    end,
    ---------------------------------------------------------
    cpp = function(name)
      local delim = delimL..delimR
      if string.find(preTxt, "^%s*#%s*include%s*")
         and delim == "<>" then                 -- system library
        for _, path in ipairs(cPaths) do        -- find system header
          local fnew = path.."/"..name
          if FileExists(fnew) then return fnew end
        end
      end
      return name
    end,
    ---------------------------------------------------------
  }
  -- lookup custom handler to use based on file extension
  function lookupExt(ext)
    for extList, handlerFn in pairs(customjobs) do
      for entry in string.gfind(props[extList], "%*%.([_%w]+)") do
        if entry == ext then return handlerFn end
      end
    end
  end
  ---------------------------------------------------------------
  -- determine extension and use of custom handlers
  ---------------------------------------------------------------
  if string.len(thisExt) > 0 and not IsAbsolute(fname) then
    local hnd = lookupExt(thisExt)
    if hnd then fname = jobfuncs[hnd](fname) end
  end
  ---------------------------------------------------------------
  -- open ze file
  ---------------------------------------------------------------
  --[[--DEBUG: PRINT DATA
  print("Prefix: "..preTxt.."\tParentExt: "..thisExt.."\n"..
        "Filename: "..fname.."\tExtension: "..fext.."\n"..
        "Delimiter L:'"..delimL.."'\tR:'"..delimR.."'")
  if lnum then print("LineNumber: "..lnum) end
  --]]
  if FileExists(fname) then     -- open file, fails silently
    scite.Open(fname)
    if lnum then                -- line number handling
      editor:GotoLine(lnum - 1)
    end
  end
end

------------------------------------------------------------------------
-- The following needs extman.lua. If you don't have extman.lua
-- installed, you can use the following in SciTEUser.properties:
--   command.name.10.*=Open Filename
--   command.10.*=OpenFilename
--   command.subsystem.10.*=3
--   command.mode.10.*=savebefore:no
--   command.shortcut.10.*=Ctrl+Shift+O
------------------------------------------------------------------------
if scite_Command then
scite_Command('Open Filename|OpenFilename|Ctrl+Shift+O')
end

------------------------------------------------------------------------
-- Useful stuff:
--
-- Test sequences for file name in a document:
--   woof ruff woof.wav [miaow|moo] {baa,moo} <miaow>
--   `tweet` "moo-moo" 'woof-woof' <moo/moo> <woof\woof>
--   perl.pl python.py c.h c.hxx c.c c.cpp c.cxx
--
-- Examples for file line number (from SciTEIO.cxx):
--   Visual Studio error message: F:\scite\src\SciTEBase.h(312):	bool Exists(
--   grep -n line, perhaps gcc too: F:\scite\src\SciTEBase.h:312:	bool Exists(
--
-- Test for file line number:
--   SciTEStartup.lua(20)
------------------------------------------------------------------------
