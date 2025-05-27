--
--
-- parseCTags.lua  a  poormans better ctags classifier
--
-- This script processes a ctags output file and generates
--    .api file for function calltips and autocompletion.
--    .properties file for symbol highlighting and categorization.
--    project.ctags.fin and .lock Files
--
-- License: BSD-3-Clause
-- Author: Thorsten Kani
-- Contact: Marcedo@habMalNeFrage.de
-- Date: 2025-05-14 (initial version)
--
-- Futter fur die Waldameisen regexps!
--
-- Parameters:
--   <project_path>       Path where output files will be written.
--   <ctags_filePath>     optional the ctags file to process (default tmp\scite.session.ctags)
--
-- handles namespaces, classes, functions, defines, simple enums / mods
--

-- Global table to hold categorized tag data
local cTagData = {
	cTagNames = "",
	cTagFunctions = "",
	cTagModules = "",
	cTagClass = "",
	cTagENUMs = ""
}

function parseString(raw)
local identifier = raw:match("\"\t([%w])") or ""

-- Functions
if identifier == "f" then 
local pat_func = "%/%^%s*([%w%s%d_:,*~=%[%]&<>\"]+)"
local pat_sig=("signature:([%w%s_(),*~=%[%]&<>\":O]+)$")
local patType = "([%s%w%d_:*<>]+ )" -- INTPTR SciteWin
str_func=raw:match(pat_func)
str_sig =raw:match(pat_sig)     
str_type=str_func:match(patType) or ""
str_func=str_func:gsub(str_type,"")
--	if not strType then strFunc = str:match(patFunc) end -- has no type
-- if not strFunc then strType,strFunc = str:match(patType.."(.*)") end --has no decoration

str_type = str_type or "" ; str_func = str_func or "";str_sig = str_sig or ""
--print(str_func..str_sig..str_type)
return {class = "f", data = str_func ..str_sig.. " " .. str_type}

-- Modules
elseif identifier == "m" then
local patNofunc = "^(%S+)%s.+\td.*$" --prefilter a bit
local patMod = "^%s*([%w_]+)%s?=" -- constval ="

local strMod=raw:match(patNofunc) or ""		
strMod = strMod:match(patMod) or ""		  

if raw:find("noexcept") then -- noexcept funcs reside only in modules
local patFunc = "%/%^(.*)$/;"
local patType = "([%s%w%d_:*<>]+ )" -- INTPTR SciteWin

-- note this sig is not reliable, grab it only for noexcept entries
local strFunc = raw:match(patFunc) or ""
local strFunc = strFunc:match("%s*(.*)") -- ltrim

-- grab the funcs type and write that behind deco
local strType=strFunc:match(patType) or "" 
local strFunc=strFunc:gsub(strType,"") or strFunc

strFunc= strFunc or "" 
strMod = strFunc..strType or ""
end
-- if str:find("MatchKeyCode") then print(str,strMod) end 
return {class = "m", data = strMod}

-- Defines
elseif identifier == "d" then
local patDef = "[%w_ ]*"
local strDef = raw:match(patDef) or ""
strDef = strDef or ""
return {class = "d", data = strDef}


elseif identifier == "t" then --typedef und using
return {class = "", data = ""}

-- Unions
elseif identifier == "u" then --union
local name = raw:match("%s*(.*)") -- ltrim
name=name:match("^%s*(.*%S?)%s*$") -- parse backwards from strings end
name=name:match("[%w_]+%s*$") or ""
return {class = "u", data = name}

elseif identifier == "s" then --struct
return {class = "", data = ""}


elseif identifier == "v" then -- AU3WordLists[]
return {class = "", data = ""}


elseif identifier == "i" then -- python import
return {class = "", data = ""}

-- ENUMs
elseif identifier == "e" then -- enum
local name = raw:match("([%w_]+)")   or ""
return {class = "e", data = name}

-- Classes
elseif identifier == "c" then -- class
local name = raw:match("([%w_]+)") or ""
return {class = "c", data = name}


elseif identifier == "n" then --namespace
local name = raw:match("([%w_]+)%s*$") or ""
return {class = "n", data = name}


elseif identifier == "g" then --enum
local name = raw:match("([%w_]+)") or ""
return {class = "g", data = name}

else
--print(identifier)
return {class = "", data = ""}
end
end
		
		
function create_files_from_table(project_path, ctags_table)
		local apiFile = io.open(project_path .. "\\scite.session.ctags.api", "w")
		if not apiFile then
			print("Fehler beim Erstellen von scite.session.ctags.api")
			return
		end

		--iterate through raw ctags table
		for _, v in ipairs(ctags_table) do
			local tbl = parseString(v) -- parse ctags line
	
			if tbl and tbl.data then
				local strClean = tbl.data:match("^%s*(.*%S?)%s*$") --trim
				--if strClean:find("MatchKeyCode") then print(tbl.class,strTmp) end
				--if strClean=="" then print(tbl.class,strTmp) end --this prints everything that could not be parsed
				if tbl.class and strClean ~= "" then
			
						apiFile:write(strClean .. "\n")
						appendProps(tbl.class, strClean)
				end
			end
		end

		apiFile:flush()
		apiFile:close()

		writeProps(project_path)
		return(true)
end
		

function appendProps(tbl_class, cleaned_data)
	if not cleaned_data then cleaned_data = "" end
	if cleaned_data ~= "" then cleaned_data = cleaned_data .. " " end 
	
	if tbl_class == "f" then
		local func_name = cleaned_data:match("([%w_]+)%s*%(") or "" -- no types or decoration
		if #func_name >1 then cTagData.cTagFunctions = cTagData.cTagFunctions .. func_name .. " "  end
		elseif tbl_class == "m" then
		local mod_name = cleaned_data:match("([%w_]+)%s*%(") or "" -- no types or decoration
		if #mod_name>1 then cTagData.cTagModules = cTagData.cTagModules .. mod_name .. " " end
		elseif tbl_class == "d" then
		cTagData.cTagNames = cTagData.cTagNames .. cleaned_data
		elseif tbl_class == "c" then
		cTagData.cTagClass = cTagData.cTagClass .. cleaned_data
		elseif tbl_class == "e" then
		cTagData.cTagENUMs = cTagData.cTagENUMs .. cleaned_data
		elseif tbl_class == "u" then
		cTagData.cTagENUMs = cTagData.cTagENUMs .. cleaned_data
		elseif tbl_class == "n" then
		cTagData.cTagClass = cTagData.cTagClass .. cleaned_data
		elseif tbl_class == "g" then
		cTagData.cTagENUMs = cTagData.cTagENUMs .. cleaned_data
	end
end
		

function writeProps(projectFilePath)
	cTagData.cTagFunctions = cTagData.cTagFunctions:gsub("::", " ")
	-- write what we got until here.
	local propFile = io.open(projectFilePath .. "scite.session.ctags.properties", "w")
	if not propFile then
		print("Error: Could not open properties file for writing.")
		return
	end

	io.output(propFile) --output file.properties
	io.write("scite.session.cTags.cTagENUMs=" .. cTagData.cTagENUMs .. "\n")
	io.write("scite.session.cTags.cTagNames=" .. cTagData.cTagNames .. "\n")
	io.write("scite.session.cTags.cTagFunctions=" .. cTagData.cTagFunctions .. "\n")
	io.write("scite.session.cTags.cTagModules=" .. cTagData.cTagModules .. "\n")
	io.write("scite.session.cTags.cTagClasses=" .. cTagData.cTagClass .. "\n")
	io.flush()
	io.close(propFile)

	-- Show some stats
	print("> cTagENUMs: (" .. string.len(cTagData.cTagENUMs) .. " bytes)")
	print("> cTagNames: (" .. string.len(cTagData.cTagNames) .. " bytes)")
	print("> cTagFunctions: (" .. string.len(cTagData.cTagFunctions) .. " bytes)")
	print("> cTagModules: (" .. string.len(cTagData.cTagModules) .. " bytes)")
	print("> cTagClass: (" .. string.len(cTagData.cTagClass) .. " bytes)")
end


function filterDummy(ctags_file, cleaned_file)
	os.execute("copy " .. ctags_file .. " " .. cleaned_file)
end

function filterGrep(ctags_file, cleaned_file)
	-- Prototyp ctags_file mit grep vorfiltern.
	--local grep_pattern = [[.*[d].*]]
	local grep_pattern = [[.*]]
	local command = "grep " .. string.format([[ %s %s > %s]], grep_pattern, ctags_file, cleaned_file)
	
	print("Starte:", command)
	local handle = io.popen(command, "r")
	local result = handle:read("*a")
	handle:close()
end

function filterFindstr(ctags_file, cleaned_file)
	-- Prototyp ctags_file mit findstr vorfiltern.
	--	fn, err = package.loadlib('..\\..\\opt\\lua\\spawner.dll', 'luaopen_spawner')
	--	if fn then fn() end -- register spawner
	
	-- Findstr-kompatibles Regex
	--local findstr_pattern = [[.*[d].*]]
	local findstr_pattern = [[.*]]
	local command = "findstr " .. string.format([[ /R %s %s > %s]], findstr_pattern, ctags_file, cleaned_file)
	
	print("Starte:", command)
	local handle = io.popen(command, "r")
	local result = handle:read("*a")
	handle:close()
	
	--[[
	local file = spawner.popen(command)
	if not file then
		print("Fehler: findstr konnte nicht gestartet werden.")
		return
	end
	for line in file:lines() do end -- synchronous quirky
	file:close()
	]]
end

--
-- Returns size of a File
--
function file_size(filename)
	local file = io.open(filename, "rb")
	if not file then
		return nil, "not found ,so no file Size."
	end

	local size = file:seek("end")
	file:close()
	return size
end

function load_file(file_path, target_table)
	local f = io.open(file_path, "r")
	if f then
		for line in f:lines() do
			table.insert(target_table, line)
		end
		f:close()
		return true
	else
		print("Fehler: konnte Datei nicht offnen:", file_path)
		return false
	end
end

function create_table_from_file(cleaned_file, api_files_string, results_table)
	if not load_file(cleaned_file, results_table) then
		return false
	end

	if api_files_string ~= "" then
		for path in string.gmatch(api_files_string, "[^;]+") do
			if not load_file(path, results_table) then
				print("Warnung: konnte API-Datei nicht offnen:", path)
			end
		end
	end
	print("Anzahl gesammelter Eintrage:", #results_table)
	return true
end

-- --- --- --- --- Start 

-- Eingabeparameter verarbeiten
local args = {...}
local defaultCtags = os.getenv("TEMP") .. [[\scite.session.ctags]]
local cleanedFile = os.getenv("TEMP") .. [[\cleaned.ctags]]
	local lock_file= os.getenv("TEMP") .. [[\project.ctags.lock]]
	local fin_file= os.getenv("TEMP") .. [[\project.ctags.fin]]
	
local projectFilePath = args[1] or ".\\"
local ctagsFile = args[2] or defaultCtags
local apiFiles = args[3] or ""
local results = {}

os.remove(fin_file)
os.remove(lock_file)

local fSize, err = file_size(ctagsFile)
if not err and fSize and fSize > 5242880 then 
	print("Error: ctags File too large. Max 5Mb.")
end

-- Create a lockfile
local lockFile = io.open(lock_file, "w")
if lockFile then
	lockFile:write(tostring(os.date()))
	lockFile:flush()
	io.close(lockFile)
else
	print("Error: Could not create lockFile.")
end

filterDummy(ctagsFile, cleanedFile)
-- filterFindstr(ctags_file, cleaned_file)
	-- filterGrep(ctags_file, cleaned_file)

if not create_table_from_file(cleanedFile, apiFiles, results) then return end
if not create_files_from_table(projectFilePath, results) then return end

-- create a finfile so sciteproject.lua knows we are done
os.remove (lock_file)
local finFile = io.open(fin_file, "w")
if finFile then
	finFile:write(tostring(os.date()))
	finFile:flush()
	io.close(finFile)
end


