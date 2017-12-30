-- (c) Valentin Schmidt 2016
-- PayPal: v.schmidt [a.t] dasdeck [d.o.t] de
-- Dec2017, Marcedo [a.t] habMalNeFrage [d.o.t] de: handle already loaded lfs lib.

if lfs==nil then err,lfs = pcall( require,"lfs")  end
local AppList = {}

-- load scripts dynamically from scripts folder
if type(lfs)=="table" then

  for f in lfs.dir(props['SciteDefaultHome'].."/user/macros") do 
     if f ~= "." and f ~= ".." then
        AppList[#AppList+1] = {f, f, f:sub(1,-5)}
     end
  end
  scite_Command('Macro Scripts|ChooseScript|Ctrl+9') 
end
-- for global scripts; switch to "SciteUserHome" for per-user scripts

local function loadscript(scriptfile)  
  dofile(props["SciteDefaultHome"].."/user/macros/"..scriptfile)
end

-- run selected scripts, silently fails if no extman
local function RunSelectedScript(str)
  for i,v in ipairs(AppList) do
    if str == v[1] then
      loadscript(v[2]) -- change this to suit your environment
      if type(_G[v[3]]) == "function" then _G[v[3]]() end
    end
  end
end

-- callback (must be global)
function ChooseScript()
  local list = {}
  for i,v in ipairs(AppList) do list[i] = v[1] end
  if scite_UserListShow then
    scite_UserListShow(list, 1, RunSelectedScript)
  end
end
