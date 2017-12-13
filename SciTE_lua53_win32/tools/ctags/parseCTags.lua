--
-- creates a SciTE .properties and .api file
-- containing translated ctags
-- todo: compile?
--
local DEBUG=1 --1: Trace Mode 2: Verbose Mode

cTagAPI={} -- projectAPI functions(param)
local cTagNames=""
local cTagFunctions=""
local cTagClass=""
local cTagModules =""
local cTagENUMs=""
local cTagOthers=""
local cTagDupes=""

--
-- Deal with different Path Separators o linux/win
--
local function dirSep()
        return("\\")
end

--
-- returns if a given fileNamePath exists
--
local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- read args
local cTagsFilePath =arg[1]
local projectName =arg[2]
local createAPIFile =arg[3]

if not cTagsFilePath then cTagsFilePath =os.getenv("tmp")..dirSep().."ctags.tags" end
local projectFilePath=string.gsub(cTagsFilePath,"ctags.tags","")

if not projectName then projectName="scite" end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
--  appendCTags(apiNames,projectFilePath,projectName)
--  Parse a ctag File, write filtered tagNames to predefined Vars.
--  Takes: apiNames: table, FullyQualified projectFilePath, optional projectName
--  Returns: uniqued tagNames written to apiNames
--
-- Optimized lua version. Gives reasonable Speed on a 100k source and 1M cTags File. 
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function appendCTags(apiNames,projectFilePath,projectName)
    local sysTmp=os.getenv("tmp")
    local cTagsFilePath=projectFilePath.."ctags.tags"
    local cTagsAPIPath=projectFilePath.."cTags.api" -- performance:  should we reuse an existing File ?
  
     -- catches not otherwise matched Stuff for Highlitghtning
     -- turn on for testing.
    local doFullSync="0"
    
    if file_exists(cTagsFilePath) then
    if DEBUG>=1 then print("ac>appendCtags" ,cTagsFilePath,projectName) end     
    
        local lastEntry=""
        local cTagsFile= io.open(cTagsAPIPath,"w")
        io.output(cTagsFile)   -- projects cTags APICalltips file

        -- a poorMans exuberAnt cTag Tokenizer :)) --
        -- Gibt den LemmingAmeisen was sinnvolles zu tun(tm) --
        
        for entry in io.lines(cTagsFilePath) do
            local isFunction=false isClass=false isConst=false isModule=false isENUM=false isOther=false
            local skipper=false          
            local name =""
            local params="" -- match function parameters for Calltips
             -- "catchAll" Names for ACList Entries
           local ACListEntry= entry:match("(~?[%w_]+)") or ""
            -- Mark Constants and Vars (matches "[tab]d/v)  
            local tmp = entry:match("%\"\t[dv]")   
            if tmp=="\"\td" or tmp=="\"\tv" then 
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
           -- Mark Modules (matches "[tab]m)  ...can have params too..
            if not skipper and entry:match("%\"\tm")=="\"\tm" then 
                strCls, name= entry:match("^([%w_]+)[%.]?([%w_]+).*")
                if name and string.len(name)==1 then name=strCls..name end                
                isModule=true
                skipper=true
            end 
            -- Mark Functions 
            if not skipper then
                name= entry:match("(~?[%w_]+)") or "" 
                patType="%/^([%s%w_:~]+ ?)" -- INTPTR
                patClass="([%w_]+).*"   -- SciteWin (::)
                patFunc="(%(.*%))"  -- AbbrevDlg(...)
                strTyp, strClass, strFunc= entry:match(patType..patClass..patFunc..".*")
                if  strFunc then params=params..strFunc end
                if  strTyp then params=params..strTyp end
                if  strClass then params=params..strClass.." =:-) " end
                if string.len(params)>0 then skipper=true isFunction=true end
            end
            -- Mark ENUMS, STRUCTs, typedefs and unions (matches "[tab]g/s/t/u/e) 
            if not skipper then
             --   if entry:match("%\"\t[geust]")   then
                if entry:match("%\"\t[geust]")   then
                    name= entry:match("([%w_]+)") or ""                    
                    isENUM=true
                    skipper=true
                end   
            end
            -- Handle Tag entries that were not tokenized before.
            -- This should normally stay empty but can be handy for new languages.
            local cTagOther=""
            if not skipper and name and name..params~=lastEntry and doFullSync=="1" then
                if string.len(name)>1 then 
                    cTagOther= entry:match("(.*%s)") 
                    if DEBUG==1 then print("other: "..entry) end
                    isOther=true;
                end
            end
            -- publish collected Data (dupe Checked). Prefer the className over the functionName  
             if name and name..params~=lastEntry and not isfunction then  
                ---- AutoComplete List entries
                if not  appendMode then cTagAPI[ACListEntry]=true end
                ----  Highlitening use String concatination, because its faster for onSave ( theres no dupe checking.)
                if DEBUG==2 then print (name,"isFunction",isFunction,"isConst:",isConst,"isModule:",isModule,"isClass:",isClass,"isENUM:",isENUM) end
                if isFunction then cTagFunctions=cTagFunctions.." "..name  end
                if isConst then cTagNames=cTagNames.." "..name end
                if isModule then cTagModules=cTagModules.." "..name end
                if isClass then cTagClass=cTagClass.." "..name  end
                if  isENUM then cTagENUMs=cTagENUMs.." "..name  end
                if isOther then cTagOthers=cTagOthers.." "..cTagOther end
                lastname=name
                -- publish Function Descriptors to Project APIFile.(calltips)
                lastEntry=name..params
                if isFunction and string.len(params)>2 then 
                   io.write(lastEntry.."\n")
                end -- faster then using a full bulkWrite
            else
                if DEBUG then cTagDupes= cTagDupes..cTagOther  end -- include Dupes for stats in Trace mode
                if DEBUG==2 then print("Dupe: "..entry) end 
            end
        end
     
        io.close(cTagsFile)
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
    
-- write whats we got until here.
    propFile=io.open(projectFilePath.."ctags.properties","w")
    propFile= io.output(propFile)
    io.output(propFile) 
    io.write("project.cTagOthers="..cTagOthers.."\n") 
    io.write("project.cTagENUMs="..cTagENUMs.."\n")     
    io.write("project.cTagNames="..cTagNames.."\n")
    io.write("project.cTagFunctions="..cTagFunctions.."\n") 
    io.write("project.cTagModules="..cTagModules.."\n")   
    io.write("project.cTagClasses="..cTagClass.."\n")
    
    io.close(propFile)
    
-- Show some stats
    if DEBUG>=1 then
        print("ac>writeProps:")
        print("ac> cTagENUMs ("..string.len(cTagENUMs).." bytes)" )
        print("ac> cTagNames: ("..string.len(cTagNames).." bytes)" )
        print("ac> cTagFunctions: ("..string.len(cTagFunctions).." bytes)" )
        print("ac> cTagModules: ("..string.len(cTagModules).." bytes)" )  
        print("ac> cTagClass: ("..string.len(cTagClass).." bytes)" )
        print("ac> cTagOthers ("..string.len(cTagOthers).." bytes)" )
        print("ac> cTagDupes ("..string.len(cTagDupes).." bytes)" )
    end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- create a lock file
finFileNamePath=os.getenv("tmp")..dirSep().."project.ctags.fin"
lockFileNamePath=os.getenv("tmp")..dirSep().."project.ctags.lock"

os.remove(finFileNamePath)
lockFile=io.open(lockFileNamePath,"w")
lockFile= io.output(lockFileNamePath)
io.output(lockFile) 
io.write(tostring(os.date))
io.close(lockFile)

-- do!
appendCTags({},projectFilePath,projectName)

-- create the fin file
os.remove(lockFileNamePath)
finFile=io.open(finFileNamePath,"w")
finFile= io.output(finFileNamePath)
io.output(finFile) 
io.write(tostring(os.date))
io.close(finFile)
