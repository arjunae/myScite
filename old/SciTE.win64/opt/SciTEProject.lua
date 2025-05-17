--
-- SciTEProject.lua, initialize Project and CTags Support for mySciTE.
-- see SciTEDirectory.properties props project.name project.path project.session.ctags project.sdk.api
-- @License: BSD3Clause. @Author Thorsten Kani
-- uses tools\ctags to write session.ctags to temp
-- uses tool\ctags\parseCTags to write session.ctags.api to projects root\ctags
-- imports session.ctags.api and.properties
-- Version: 1.0 rc2 14.05.25
--

local DEBUG=0 --2 verbose Mode
local ctagsLock --true during writing to the projects ctags and properties. (handles case: multiple saves in a row)   
--
-- NameCache
--
local cTagNames=""
local cTagClasses=""
local cTagModules=""
local cTagFunctions=""
local cTagNames=""
local cTagENUMs=""
local cTagOthers=""
local cTagAllTogether=""
local cTagList --table

--
-- Default Values for syntax Highlitening for substyles enabled Lexers
--
if props["colour.project.class"]=="" then props["colour.project.class"]="fore:#906690" end 
if props["colour.project.functions"]=="" then props["colour.project.functions"]="fore:#907090" end 
if props["colour.project.constants"]=="" then props["colour.project.constants"]="fore:#B07595" end 
if props["colour.project.modules"]=="" then props["colour.project.modules"]="fore:#9675B0" end 
if props["colour.project.enums"]=="" then props["colour.project.enums"]="fore:#3645B0" end 

-- returns if a given fileNamePath exists
--
--
local function file_exists(filename)            -- Tests for file or directory
    if type(filename)~="string" then
	    return false
    end
    return os.rename(filename,filename) and true or false
 end

-- returns if a given Dir exists
--
--
function dir_exists(path)
    local ok, err, code = os.rename(path, path)
    return ok or code == 13  -- 13 = permission denied (means it exists)
end

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- init Project Folders
-- (ctags, Autocomplete & highlitening)
function ProjectSetEnv()

	props["properties.directory.enable"]=1
	if props["SciteDirectoryHome"] ~="" then projectHome= props["SciteDirectoryHome"]
		elseif file_exists(props["FileDir"]..dirSep.."SciTE.properties") then
		 projectHome= props["FileDir"]..dirSep.."SciTE.properties"
	end
	if props["project.name"] ~="" then
		props["project.inProject"] = 1
		props["project.path"] = projectHome
		props["project.session.api"]=props["project.path"]..dirSep.."ctags"..dirSep.."scite.session.ctags"..".api"
		props["project.session.props"]=props["project.path"]..dirSep.."ctags"..dirSep.."scite.session.ctags"..".properties"
		props["project.info"] = "{"..props["project.name"].."}->"..props["FileNameExt"]
		props["project.ctags.bin"]="myctags.cmd" -- invokes parseCTags.lua which creates a lockfile 
	else
		props["project.info"] =props["FileNameExt"] -- Display filename in StatusBar1
		props["project.inProject"] = 0
	end
	
end

--
-- CTagsImportProps() / publish cTag extrapolated Api Data to scites props -
-- reads session.cTag.properties File and writes them to SciTEs .properties buffer.
-- prepared for just appending a set of filebased Ctags for speed.
-- returns cTagList, which contains a List of all Names found in the tagFile
--
function CTagsImportProps(theForceMightBeWithYou, YodaNamePath)

	if not file_exists(YodaNamePath) or ctagsLock==true or props["project.path"]=="" then return end	
	-- just return the cached Version if not forced to do otherwise
	if (not cTagList) or string.find(YodaNamePath,"append.") then theForceMightBeWithYou=true end

	-- Propagate the Data, appends if required
	if  (theForceMightBeWithYou==true) then
		for entry in io.lines(YodaNamePath) do
			prop,names=entry:match("([%w_.]+)%s?=(.*)") 
			if prop:match(".cTagClasses") then cTagClasses= cTagClasses.." "..names  end
			if prop:match(".cTagModules") then cTagModules = cTagModules.." "..names end
			if prop:match(".cTagFunctions") then cTagFunctions = cTagFunctions.." "..names end
			if prop:match(".cTagNames") then cTagNames= cTagNames.." "..names end
			if prop:match(".cTagENUMs") then cTagENUMs= cTagENUMs.." "..names end
			if prop:match(".cTagOthers") then cTagOthers =cTagOthers.." "..names end
			-- if prop:match(".cTagAllTogether") then cTagAllTogether =cTagAllTogether..names end --: table formatted
		end
		--cTagList=cTagAllTogether
		cTagList={}
		
		-- Write dynamically created Project SDK to Scites Config.
		projectEXT=props["file.patterns.project"]
		props["substylewords.11.15."..projectEXT] = cTagOthers
		props["substylewords.11.16."..projectEXT]= cTagNames
		props["substylewords.11.17."..projectEXT] = cTagFunctions
		props["substylewords.11.18."..projectEXT] = cTagModules
		props["substylewords.11.19."..projectEXT] = cTagENUMs
		props["substylewords.11.20."..projectEXT] = cTagClasses

		-- Same for User Provided Platform SDK
		props["substylewords.11.10."..projectEXT] = props["sdk.tags.cTagNames"]
		if props["sdk.tags.cTagFunctionsEx"]~="" then
			props["substylewords.11.11."..projectEXT] = props["sdk.tags.cTagFunctions"].." "..props["sdk.tags.cTagFunctionsEx"]
		else
			props["substylewords.11.11."..projectEXT] = props["sdk.tags.cTagFunctions"]
		end
		props["substylewords.11.12."..projectEXT] = props["sdk.tags.cTagModules"]
		props["substylewords.11.13."..projectEXT] = props["sdk.tags.cTagENUMs"]
		props["substylewords.11.14."..projectEXT] = props["sdk.tags.cTagClasses"]		
	end
	--print(props["substylewords.11.14."..projectEXT] )
	-- Do we also want to detect changed Styles and apply them here ?
	-- Define the Styles for cTag types
	local currentLexer=props["Language"]
	props["substyles."..currentLexer..".11"]=20

	-- User Provided platformSDK (eg MinGW)
	props["style."..currentLexer..".11.10"]=props["colour.project.constants"]
	props["style."..currentLexer..".11.11"]=props["colour.project.functions"]
	props["style."..currentLexer..".11.12"]=props["colour.project.modules"]
	props["style."..currentLexer..".11.13"]=props["colour.project.enums"]
	props["style."..currentLexer..".11.14"]=props["colour.project.class"]
	--Dynamically created Project SDK
	props["style."..currentLexer..".11.15"]=props["colour.project.enums"] --others    
	props["style."..currentLexer..".11.16"]=props["colour.project.constants"]
	props["style."..currentLexer..".11.17"]=props["colour.project.functions"]
	props["style."..currentLexer..".11.18"]=props["colour.project.modules"]
	props["style."..currentLexer..".11.19"]=props["colour.project.enums"]
	props["style."..currentLexer..".11.20"]=props["colour.project.class"]

	return cTagList
end

local origApiPath, projectApiPath, sdkApiPath

--
--CTagsImportAPI()  reads props["project.session.api"] and props["project.sdk.api"]
--
function CTagsImportAPI(theForceMightBeWithYou,fileNamePath)

	ProjectSetEnv()

	if cTagList and sdkApiPath and sdkApiPath==props["project.sdk.api"] then return end --Already done ?
	if props["project.path"]=="" then return end
	if not fileNamePath or fileNamePath=="" then fileNamePath=props["project.session.props"] end
	props["api."..props["file.patterns.project"]] =""


	-- Attach a project platform API if it had been specified
	if (props["project.sdk.api"]~="") then sdkApiPath=props["project.sdk.api"] end
	if not sdkApiPath then sdkApiPath="" end
	-- Oprionally Update SciTEs APIlist property. 
	if not projectApiPath or not projectApiPath:match(props["project.sdk.api"]) then
		props["api."..props["file.patterns.project"]] =props["project.session.api"]..";"..sdkApiPath
	end

	-- parse projects properties files
	CTagsImportProps(theForceMightBeWithYou,fileNamePath)

end

-- 
-- ProjectOnDwell()
-- Performs actions when the "project.ctgs.fin" file has been found.
-- (created when a cTag run has been completed)
--
function ProjectOnDwell()

	if props["project.path"]=="" then return end	--- not in a file contained by the project
	finFileNamePath=os.getenv("tmp")..dirSep.."project.ctags.fin"	
	local finFile=io.open(finFileNamePath,"r")
	if finFile~=nil then 
	if DEBUG==1 and finFilenamePath then print("ProjectOnDwell, project.path: " , props["project.path"], " updated CTAGS found" ) end
		io.flush()
		io.close(finFile)
		ctagsLock=false
		os.remove(finFileNamePath)
		if DEBUG==1 then print("ProjectOnDwell, CTags file was updated. Found ", finFileNamePath) end 	
		local fileNamePath= (props["project.session.props"])
		CTagsImportAPI(true,fileNamePath)
	end
	finFile=nil

end

--
-- RecreateCTags()
-- Search the File for new CTags and append them.
--

function CTagsRecreate()
	if  ctagsLock==true then return end
	if props["project.name"]~="" and props["file.patterns.project"]:match(props["FileExt"])~=nil then
		toolPath=props["SciteDefaultHome"]..dirSep.."tools"
		ctagsBin=props["project.ctags.bin"]
		ctagsOpt=props["project.ctags.opt"] -- options
		
		ctagsTMP="\""..os.getenv("tmp")..dirSep.."scite.session.ctags\"" -- raw .ctags go here
		ctagsAPI=props["project.path"].."\\ctags\\ " -- parsed .api goes here
		os.remove(os.getenv("tmp")..dirSep.."*.session.ctags")

		if ctagsBin and ctagsOpt then
		--cTags doesnt start without this (in our configuration)
		if not dir_exists(props["project.path"]..dirSep.."ctags") then os.execute("mkdir " .. trim(props["project.path"])..dirSep.."ctags") end
			local fExcludes=trim(props["project.path"])..dirSep.."ctags"..dirSep.."ctags.excludes"	
			if not file_exists(fExcludes) then local file , err= io.open(fExcludes, "w") ; file:close() end
 		-- start collecting cTags
				ctagsCMD=toolPath..dirSep..ctagsBin.." "..ctagsOpt.." -f "..ctagsTMP.." -R " ..props["project.path"] 
				if DEBUG==1 then print("CTagsRecreate All, starting " .. props["project.path"] ) end 

			local pipe=scite_Popen(ctagsCMD)
			local tmp= pipe:read('*a'); --print (tmp)

			local pipe=scite_Popen(toolPath..dirSep.."mylua.cmd tools\\ctags\\parseCTags.lua "..ctagsAPI.." "..ctagsTMP)
			if DEBUG==2 then 
				local tmp= pipe:read('*a') ; print (tmp)  -- synchronous -waits for the Command to complete
			end

			scite_OnDwellStart(ProjectOnDwell) -- periodically check if ctags refresh has been finished.
			ctagsLock=true	
		end
	end	
end

-- remove previous lockfile
local lockfile = os.getenv("tmp") .. dirSep .. "project.ctags.lock"
local success, err = os.remove(lockfile)

-- Registers the event Handlers early.	
ProjectSetEnv()
scite_OnOpenSwitch(CTagsImportAPI,false,"")
scite_OnDwellStart(ProjectOnDwell)
scite_OnSave(CTagsRecreate)
