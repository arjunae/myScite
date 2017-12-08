
--
-- todo: should write a scite prop and api file
--todo: compile
--
local DEBUG=1 --1: Trace Mode 2: Verbose Mode

cTagAPI={} -- projectAPI functions(param)
local cTagNames=""
local cTagFunctions=""
local cTagClass=""
local cTagModules =""
local cTagENUMs=""
local cTagOthers=""
local cTagDupes="" -- Used

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

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
--  appendCTags(apiNames,cTagsFilePath,dryRun)
--  Parse a ctag File, write filteret tagNames to predefined Vars.
--  Takes: apiNames: table, FullyQualified cTagsFilePath, createAPIFile: optionally write Api file to tmp.
--  Returns: uniqued tagNames to given table
--
-- Optimized lua version. Gives reasonable Speed on a 100k source and 1M cTags File. 
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function appendCTags(apiNames,cTagsFilePath,projectName,createAPIFile)
    local sysTmp=os.getenv("tmp")
    local cTagsAPIPath=sysTmp..dirSep()..projectName.."_cTags.api" -- performance:  should we reuse an existing File ?
    local cTagsUpdate

   if not cTagsUpdate then cTagsUpdate="1" end
 --   if projectName=="" then return apiNames end

     -- catches every single bit of stuff for Highlitghtning
     -- turn on for testing.
    local doFullSync="0"

    if file_exists(cTagsFilePath)  and (cTagsUpdate=="1" or createAPIFile==0) then
    if DEBUG>=1 then print("ac>appendCtags" ,cTagsFilePath, short) end         
    
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
            -- publish collected Data (dupe Checked)  
             if name and name..params~=lastEntry then 
                if name~=lastname then 
                    ---- AutoComplete List entries
                    if not  appendMode then cTagAPI[ACListEntry]=true end
                    ----  Highlitening use String concatination, because its faster for onSave ( theres no dupe checking.)
                    if DEBUG==2 then print (name,"isFunction",isFunction,"isConst:",isConst,"isModule:",isModule,"isClass:",isClass,"isENUM:",isENUM) end
                    if  isFunction then cTagFunctions=cTagFunctions.." "..name  end
                    if isConst then cTagNames=cTagNames.." "..name end
                    if  isModule then cTagModules=cTagModules.." "..name end
                    if  isClass then cTagClass=cTagClass.." "..name  end
                    if  isENUM then cTagENUMs=cTagENUMs.." "..name  end
                    if  isOther then cTagOthers=cTagOthers.." "..cTagOther end
                    lastname=name
                else
                    if DEBUG then cTagDupes= cTagDupes..cTagOther  end -- include Dupes for stats in Trace mode
                    if DEBUG==2 then print("Dupe: "..entry) end 
                end
                -- publish Function Descriptors to Project APIFile.(calltips)
                lastEntry=name..params
                if isFunction and string.len(params)>2 then 
                   if createAPIFile then io.write(lastEntry.."\n") end
                end -- faster then using a full bulkWrite
            end
        end

        io.close(cTagsFile)

        cTagsUpdate=0
        writeProps(projectName) -- Helper which applies the generated Data to their lexer styles

end

    -- cTagsUpdate=0 so already done.  Using the cached Version
    return cTagAPI  
end


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- writeProps()
-- publish cTag extrapolated Api Data -
-- reads above cTag.* vars
-- write them to SciTEs properties
-- probably should return something useful
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function writeProps(projectName)

if DEBUG>=1 then
    print("ac>writeProps:")
    print("ac> cTagNames: ("..string.len(cTagNames).." bytes)" )
    print("ac> cTagClass: ("..string.len(cTagClass).." bytes)" )
    print("ac> cTagModules: ("..string.len(cTagModules).." bytes)" )  
    print("ac> cTagFunctions: ("..string.len(cTagFunctions).." bytes)" )
    print("ac> cTagENUMs ("..string.len(cTagENUMs).." bytes)" )
    print("ac> cTagOthers ("..string.len(cTagOthers).." bytes)" )
    print("ac> cTagDupes ("..string.len(cTagDupes).." bytes)" )
end

propFile=io.open(os.getenv("tmp")..dirSep()..projectName..".properties")
propFile= io.output(propFile)
io.output(propFile) 
io.write("projectName.cTagClasses="..cTagClass)
io.write("projectName.cTagModules="..cTagModules) 
io.write("projectName.cTagFunctions="..cTagFunctions) 
io.write("projectName.cTagNames="..cTagNames)
io.write("projectName.cTagENUMs="..cTagENUMs)
io.write("projectName.cTagOthers="..cTagOthers) 
io.close(propFile)

end

appendCTags({},"D:\\projects\\_myScite\\_myScite.github\\src.lua53\\ctags.tags","scintilla_scite",true)