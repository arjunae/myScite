--
-- parseCTags.lua 
--
-- This script processes a ctags output file and generates
--    .api file for function calltips and autocompletion.
--    .properties file for symbol highlighting and categorization.
--    project.ctags.fin and .lock Files
-- 
-- License: BSD-3-Clause
-- Author: Thorsten Kani
-- Contact: Marcedo@habMalNeFrage.de
-- Date: 2025-04-28 (Proof-of-Concept version)
--
-- Parameters:
--   <project_path>       Path where output files will be written.
--   <ctags_filePath>     the ctags file to process (with or without path).
--
-- Limits: only (Member)functions. No defines, structs, unions or enums.
--~~~~~~~~~~~~~~~~~~~~~~~~~~~

local DEBUG=0 --1: Trace Mode 2: Verbose Mode
io.stdout:setvbuf("no")

cTagAPI={} -- projectAPI functions(param)
local cTagNames=""
local cTagFunctions=""
local cTagClass=""
local cTagModules =""
local cTagENUMs=""
local cTagOthers=""
local cTagAllTogether="{"
local projectFilePath, cTagsFileName, odo
local fs=io

--
-- Deal with different Path Separators o linux/win
--
local dirSep = package.config:sub(1,1)

--
-- returns if a given fileNamePath exists
--
local function file_exists(name)
   local f=fs.open(name,"r")
   if f~=nil then fs.close(f) return true else return false end
end

-- read args
local projectFilePath=arg[1]
local cTagsFilePath =arg[2]

print("> ["..arg[0].."] [Thorsten Kani / Dezember 2017 / eMail:Marcedo@HabMalNeFrage.de]")

if not arg[1] then 
    print ("> ["..arg[0].."] [File] (cTags Filename) [True] (strip Datastructures)")
    odo=false
else
    odo=true
    if smallerFile=="1" then smallerFile=true end

    -- when theres no pathseperator given, interpret a filename
    if cTagsFilePath:match(dirSep)==nil then 
        cTagsFileName=cTagsFilePath
        cTagsFilePath="."..dirSep..cTagsFileName -- Think that the file is local
    end	

    cTagsFileName =cTagsFilePath:match(".*\\%/?(.*)$")
    if not projectName then projectName=cTagsFileName end
    print ("projectFilePath: "..tostring(projectFilePath).."| cTagsFilePath: "..tostring(cTagsFilePath).."| cTagsFileName: "..tostring(cTagsFileName) )

end


--
--  appendCTags(apiNames,projectFilePath,projectName)
--  Parse a ctag File, write filtered tagNames to predefined Vars.
--  Takes: apiNames: table, FullyQualified projectFilePath,cTagsFileName, optional projectName
--  Returns: uniqued tagNames written to apiNames
--
-- Optimized lua version. Gives reasonable Speed even with bigger cTags Files. 
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function appendCTags(apiNames,projectFilePath,cTagsFileName,projectName)
    local cTagsFilePath=os.getenv("tmp")..dirSep.."scite.session.ctags"
    local cTagsAPIPath=projectFilePath..cTagsFileName..".api"
    local cTagItems=""
    -- catches not otherwise matched Stuff for Highlitghtning. Turn on for testing.
    local doFullSync="0"

    if file_exists(cTagsFilePath) then
    if DEBUG>=1 then print("ac>appendCtags" ,cTagsFilePath,projectName) end     
        io.stdout:write("> parse: "..cTagsFilePath .." ")
        local lastEntry="" -- simple DupeCheck
        local apiFile= io.open(cTagsAPIPath,"w") --  Output file.api

        cTagsFile=io.input(cTagsFilePath) -- Input file.ctags
	if not cTagsFile then print("no valid handle to ctagsFile") end
        fileSize=cTagsFile:seek("end")
        cTagsFile:seek("set")
        
        -- a poorMans exuberAnt cTag Tokenizer :)) --
        -- Gibt den LemmingAmeisen was sinnvolles zu tun(tm) --
	
	if DEBUG==2 then print ("\n") end
        for entry in cTagsFile:lines() do
           -- print(entry)
            filePos=cTagsFile:seek()
            percent_before= percent
            percent=math.floor(filePos*100/fileSize) 
            if percent~=percent_before then  
             if DEBUG==0 then
		io.stdout:write(string.format("%02d",percent).."% ")
                io.stdout:write('\b'..'\b'..'\b'..'\b')
	     end
            end
            
            local isFunction=false isClass=false isConst=false isModule=false isENUM=false isOther=false
            local skipper=false          
            local name =""
            local params="" -- match function parameters for Calltips           
            -- Mark Constants and Vars (matches "[tab]v)  
            local tmp = entry:match("%\"\t[v]")   
            if not smallerFile and (tmp=="\"\tv") then 
                name= entry:match("([%w_]+)") or "" 
                isConst=true
                skipper=true
            end   
            -- Mark Classes & Namespaces (matches "[tab]c/n)
            if not skipper then
                local tmp = entry:match("%\"\t[cn]")   
                if tmp=="\"\tc" or tmp=="\"\tn"  then 
                    name= entry:match("([%w_]+)") or "" 
                    isClass=true
                    skipper=true
                end   
           end     
            -- Mark Functions 
            name= entry:match("(~?[%w_]+)") or "" -- functions Name
            if not name then name="" end
	    if string.find(name,"override") then name=""; skipper=true end-- ctags doesnt parse this correctly
	    patType="%/^([%s%w_:~]+ )" -- INTPTR
            patClass="([%w_:]+).*"   -- SciteWin (::)
            patFunc="(%(.*%))"  -- (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)) 
            strTyp, strClassAndName, strFunc= entry:match(patType..patClass..patFunc..".*")

            if strFunc then params=params..strFunc end --functionbody
 	    if strTyp then strTyp=strTyp:gsub("^%s+", ""); params=params..strTyp end --typ hinter funktionsbody schreiben

		if name and DEBUG==2 then
		if not strTyp then strTyp="" end
		if not strClassAndName then strClassAndName="" end
		if not strFunc then strFunc ="" end
		print (strTyp.. "|".. strClassAndName, "|".. name.. "|".. strFunc)
		end
		
            if string.len(params)>0 then skipper=true isFunction=true end
            -- Mark ENUMS, STRUCTs, typedefs and unions (matches "[tab]g/s/t/u/e) 
            if not smallerFile and not skipper then
                if entry:match("%\"\t[geust]") then
                    name= entry:match("([%w_]+)") or ""
                    isENUM=true
                    skipper=true
                end   
            end
            -- Mark Modules / defines wo params (matches "[tab]m "[tab]d )
            if not skipper and entry:match("%\"\tm")=="\"\tm" or entry:match("%\"\td")=="\"\td" then 
                strCls, name= entry:match("^([%w_]+)[%.]?([%w_]+).*")
                if name and string.len(name)==1 then name=strCls..name end
                isModule=true
                skipper=true
            end
            -- Handle Tag entries that were not tokenized before.
            -- This should normally stay empty but can be handy for new languages.
            local cTagOther=""
            if not smallerFile and not skipper and name and name..params~=lastEntry and doFullSync=="1" then
                if string.len(name)>1 then 
                    cTagOther= entry:match("(.*%s)") 
                    if DEBUG==1 then print("other: "..entry) end
                    isOther=true;
                end
            end
            -- publish collected Data. (Dupe checked) Prefer the className over the functionName  
             if name and name..params~=lastEntry and not isfunction then  
		if not strClassAndName then strClassAndName=name end
                ----  Highlitening use String concatination, because its faster for onSave ( theres no dupe checking.)
                --if DEBUG==2 then print (name,"isFunction",isFunction,"isConst:",isConst,"isModule:",isModule,"isClass:",isClass,"isENUM:",isENUM) end
                if isFunction then cTagFunctions=cTagFunctions.." "..name  end
                if isConst then cTagNames=cTagNames.." "..name end
                if isModule then cTagModules=cTagModules.." "..name end
                if isClass then cTagClass=cTagClass.." "..name end
                if isENUM then cTagENUMs=cTagENUMs.." "..name end
                if isOther then cTagOthers=cTagOthers.." "..cTagOther end
                if smallerFile==true then
                  -- if isFunction then cTagItems=cTagItems..","..name.."=true" end -- gets concatenated to table cTagAllTogether
                else
                   cTagItems=cTagItems..strClassAndName.."=true," 
                end   
                lastname=name

                -- publish Function Descriptors to Project APIFile.(calltips)
                lastEntry=strClassAndName..params
                if isFunction and string.len(params)>2 then  -- Optionally Filter internals and COM Objects
                    if  smallerFile and (lastEntry:match("^(_)") or lastEntry:match("_Proxy") or lastEntry:match("_Stub") or lastEntry:match("Vtbl")   ) then
                         entry=""
                        else
                        apiFile:write(lastEntry.."\n")  
                   end
                end -- faster then using a full bulkWrite?!
            end
        end
        ---- AutoComplete List entries
        cTagAllTogether=cTagAllTogether..cTagItems.."}"
        cTagAPI=cTagAllTogether
	io.close(apiFile)
        writeProps(projectName, projectFilePath) --> Let a Helper apply the generated Data.
        cTagsUpdate="0"
    end

    -- cTagsUpdate=0 so already done.  Using the cached Version
    return cTagAPI  
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- writeProps(projectName, projectFilePath)
-- publish cTag extrapolated Api Data -
-- reads above cTag.* vars
-- write them to SciTEs properties
-- probably should return something useful.
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function writeProps(projectName, projectFilePath)
    
-- write what we got until here.
    propFile=io.open(projectFilePath..cTagsFileName..".properties","w")
    propFile= io.output(propFile)
    io.output(propFile) --output file.properties
    io.write(projectName..".cTagOthers="..cTagOthers.."\n")
    io.write(projectName..".cTagENUMs="..cTagENUMs.."\n")
    io.write(projectName..".cTagNames="..cTagNames.."\n")
    io.write(projectName..".cTagFunctions="..cTagFunctions.."\n")
    io.write(projectName..".cTagModules="..cTagModules.."\n")
    io.write(projectName..".cTagClasses="..cTagClass.."\n")
--    io.write(projectName..".cTagAllTogether="..cTagAllTogether.."\n") --: Table formatted
    io.flush()
    io.close(propFile)
    
-- Show some stats
        print("")
        print("> cTagENUMs: ("..string.len(cTagENUMs).." bytes)" )
        print("> cTagNames: ("..string.len(cTagNames).." bytes)" )
        print("> cTagFunctions: ("..string.len(cTagFunctions).." bytes)" )
        print("> cTagModules: ("..string.len(cTagModules).." bytes)" )
        print("> cTagClass: ("..string.len(cTagClass).." bytes)" )
        print("> cTagOthers: ("..string.len(cTagOthers).." bytes)" )
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--DeDupeAPI() 
--Removes Dupes by storing entries as TableKeys
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function DeDupeAPI(APIFilePath)
nameTable={}
outline=""
print("> deDupeing.."..APIFilePath)

    for entry in io.lines(APIFilePath) do

        name =entry:match("^([%w_:]+)")
        params=entry:match("[%w_]+(%(.*%))")
        retval=entry:match("%)(.*)")
        if not params then params="()" end
        if not retval then retval="()" end

        if name then nameTable[name..params]=retval end
    end

    -- Store the Result
    ResultFile=io.open(APIFilePath,"w")
    ResultFile= io.output(APIFilePath)
    io.output(APIFilePath) 
    for key,val in pairs(nameTable) do
    io.write(key..val.."\n")
    end
    io.flush()
    io.close(ResultFile)
 --   os.remove(APIFilePath)
   -- os.rename("ResultFile",APIFilePath)

end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if odo then
    APIFilePath=projectFilePath..cTagsFileName..".api"
    finFileNamePath=os.getenv("tmp")..dirSep.."project.ctags.fin"
    lockFileNamePath=os.getenv("tmp")..dirSep.."project.ctags.lock"

    -- create a lock file
    os.remove(finFileNamePath)
local lockFile = io.open(lockFileNamePath, "w")
if lockFile then
    lockFile:write(os.date())
    lockFile:flush()
    lockFile:close()
else
    print("Fehler beim Erstellen der Lock-Datei: " .. lockFileNamePath)
end

    -- do!
    appendCTags({},projectFilePath,cTagsFileName,projectName)
    if file_exists(APIFilePath) then
        DeDupeAPI(APIFilePath) 
        print("> FIN!")
    else
        print("> Error: "..APIFilePath.." was not found")
    end


    os.remove(lockFileNamePath) -- remove lock
    finFile=io.open(finFileNamePath,"w")     -- create the fin file signalling sciteproject.lua that the output files are ready
    finFile= io.output(finFileNamePath)
    io.output(finFile) 
    io.write(tostring(os.date))
    io.flush()
    io.close(finFile)
end
