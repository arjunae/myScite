-- Prototyp ctags_file mit findstr vorfiltern. 
fn, err = package.loadlib('..\\..\\opt\\lua\\spawner.dll', 'luaopen_spawner')
if fn then fn() end -- register spawner

-- Eingabeparameter verarbeiten
local args = {...}
local default_ctags = os.getenv("TEMP") .. [[\scite.session.ctags]]
local projectFilePath= args[1]
local ctags_file = args[2] or default_ctags 
local api_files = args[3] or ""

-- Findstr-kompatibles Regex
local findstr_pattern = [[.*[d].*]]

local cleaned_file = os.getenv("TEMP") .. [[\cleaned.ctags]]
local command = "findstr "..string.format([[ /R %s %s > %s]], findstr_pattern, ctags_file, cleaned_file)

print("Starte:", command)
local file = spawner.popen(command)
if not file then
  print("Fehler: findstr konnte nicht gestartet werden.")
  return
end

for line in file:lines() do end --quirk makes it synchronous

local results = {}
local f = io.open(cleaned_file, "r")
if f then
  for line in f:lines() do
    table.insert(results, line)
  end
  f:close()
else
  print("Fehler: konnte cleaned.ctags nicht öffnen.")
  return
end
file:close()

if api_files ~= "" then
  for path in string.gmatch(api_files, "[^;]+") do
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        if line ~= "" then
          table.insert(results, line)
        end
      end
      f:close()
    else
      print("Warnung: konnte API-Datei nicht öffnen:", path)
    end
  end
end

print("Anzahl gesammelter Einträge:", #results)

-- Lua-Pattern zum Extrahieren der Funktions-/Klassennamen
local pat_func = "%/%^%s?([%w%s_:(),*~=%[%]]+)"  --nicht greedy pattern. ~ für destructoren, * für pointer etc

local apiFile = io.open(projectFilePath.."\\scite.session.ctags.api", "w")
if not apiFile then print("Fehler beim Erstellen von scite.session.ctags.api") end
local pat_name = "%/%^%s?([%w%s_:(),*~=%[%]&]+)"
local pat_define = "^(%S+)%s.+\td.*$"

for _,v in ipairs(results) do
    local strClean =  v:match(pat_name) or v:match(pat_define)  or ""
--todo jetzt klassifizieren
	apiFile:write(strClean.."\n")
end

 apiFile:flush()
 apiFile:close()

 finFile=io.open("finfile","w")     -- create the fin file signalling sciteproject.lua that the output files are ready
 finFile:write(tostring(os.date))
 finFile:flush()
 io.close(finFile)
