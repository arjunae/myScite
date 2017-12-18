--
-- SciTEProject.lua, base Module: initialize Project and CTags Support for mySciTE.
-- @License: BSD3Clause. @Author Thorsten Kani
-- Version: 0.8
-- todo: test implementation scite.ReadProperties
--

local ctagsLock --true during writing to the projects ctags and properties files 

--~~~~~~~~~~~~~~~~~~~
--
-- NameCache
--
--~~~~~~~~~~~~~~~~~~~
local cTagNames=""
local cTagClasses=""
local cTagModules=""
local cTagFunctions=""
local cTagNames=""
local cTagENUMs=""
local cTagOthers=""
local cTagAllTogether=""
local cTagList --table

--~~~~~~~~~~~~~~~~~~~
--
-- Default Values for syntax Highlitening for substyles enabled Lexers
--
--~~~~~~~~~~~~~~~~~~~
if props["colour.project.class"]=="" then props["colour.project.class"]="fore:#906690" end 
if props["colour.project.functions"]=="" then props["colour.project.functions"]="fore:#907090" end 
if props["colour.project.constants"]=="" then props["colour.project.constants"]="fore:#B07595" end 
if props["colour.project.modules"]=="" then props["colour.project.modules"]="fore:#9675B0" end 
if props["colour.project.enums"]=="" then props["colour.project.enums"]="fore:#3645B0" end 

--~~~~~~~~~~~~~~~~~~~
--
-- returns if a given fileNamePath exists
--
--~~~~~~~~~~~~~~~~~~~
local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

--~~~~~~~~~~~~~~~~~~~
--
-- handle Project Folders
-- (ctags, Autocomplete & highlitening)
--
--~~~~~~~~~~~~~~~~~~~
function ProjectSetEnv(init)

	if props["SciteDirectoryHome"] ~= props["FileDir"] then
		props["project.path"] = props["SciteDirectoryHome"]
		props["project.ctags.filename"]="ctags.tags"
		props["project.ctags.apipath"]=props["project.path"]..dirSep..props["project.ctags.filename"]..".api"
		props["project.ctags.propspath"]=props["project.ctags.apipath"]..".properties"
		props["project.info"] = "{"..props["project.name"].."}->"..props["FileNameExt"]
		buffer.projectName= props["project.name"]
	else
		props["project.info"] =props["FileNameExt"] -- Display filename in StatusBar1
	end
	
	if init then dofile(myHome..'\\macros\\AutoComplete.lua') end

end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- CTagsWriteProps() / publish cTag extrapolated Api Data -
-- reads cTag.properties and writes them to SciTEs .api and .properties files.
-- prepared for just appending a set of filebased Ctags for speed.
-- returns cTagList, which contains a List of all Names found in the tagFile
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CTagsWriteProps(theForceMightBeWithYou, YodaNamePath)

	if not file_exists(YodaNamePath) or ctagsLock==true or props["project.path"]=="" then return end		
	-- just return the cached Version if not forced to do otherwise
	if (not cTagList) or string.find(YodaNamePath,"append.") then theForceMightBeWithYou=true end

	-- Propagate the Data, appends if required
	if  (theForceMightBeWithYou==true) then
	cTagList={}
		for entry in io.lines(YodaNamePath) do
			prop,names=entry:match("([%w_.]+)%s?=(.*)") 
			if prop:match(".cTagClasses") then cTagClasses= cTagClasses.." "..names  end
			if prop:match(".cTagModules") then cTagModules = cTagModules.." "..names end
			if prop:match(".cTagFunctions") then cTagFunctions = cTagFunctions.." "..names end
			if prop:match(".cTagNames") then cTagNames= cTagNames.." "..names end
			if prop:match(".cTagENUMs") then cTagENUMs= cTagENUMs.." "..names end
			if prop:match(".cTagOthers") then cTagOthers =cTagOthers.." "..names end
--			if prop:match(".cTagAllTogether") then cTagAllTogether =cTagAllTogether..names end --: table formatted
		end
--		cTagList=cTagAllTogether
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
		props["substylewords.11.10"..projectEXT] = props["sdk.tags.cTagNames"]
		props["substylewords.11.11."..projectEXT] = props["sdk.tags.cTagFunctions"]
		props["substylewords.11.12."..projectEXT] = props["sdk.tags.cTagModules"]
		props["substylewords.11.13."..projectEXT] = props["sdk.tags.cTagENUMS"]	
		props["substylewords.11.14."..projectEXT] = props["sdk.tags.cTagClasses"]		
	end

	return cTagList
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
--cTagsUpdateProps() 	/ Update filetypes api path.
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CTagsUpdateProps(theForceMightBeWithYou,fileNamePath)
	local origApiPath, projectPlatApiPath, projectApiPath

	ProjectSetEnv(false)
	if props["project.path"]=="" then return end
	if not fileNamePath or fileNamePath=="" then fileNamePath=props["project.ctags.propspath"] end
	
	-- Attach a project platform API if it had been specified
	if (props["project.libapi"]~="") then projectPlatApiPath=props["project.libapi"] end
	if not projectPlatApiPath then projectPlatApiPath="" end
	
	-- Update SciTEs Filetypes APIlist
	if origApiPath==nil then 
		origApiPath=props["APIPath"]
		projectApiPath=props["project.ctags.apipath"]
		if not origApiPath:match(projectPlatApiPath) then projectApiPath=projectApiPath..";"..projectPlatApiPath end
		props["api."..props["file.patterns.project"]] =origApiPath..";"..projectApiPath
	end
	
	-- parse projects properties files
	CTagsWriteProps(theForceMightBeWithYou,fileNamePath)
	-- write user supplied library Api
	projectLibPath =props["project.libprops"]
	projectLibPath:gsub("[^;]+", function(lib) -- For each in ;-delimited list.	
		if lib~="" then CTagsWriteProps(true,lib) end
	end)
	
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

	--apply themeing changes and changed keywords.
	scite.ApplyProperties()
	 
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 
-- ProjectOnDwell()
-- Performs actions when the "project.ctgs.fin" file has been found.
-- (created when a cTag run has been completed)
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~
function ProjectOnDwell()
	if ctagsLock==false or props["project.path"]=="" then return end	
	--print("ProjectOnDwell: cTagsLock",ctagsLock,"inProject",inProject)	
	finFileNamePath=os.getenv("tmp")..dirSep.."project.ctags"..".fin"
	
	local finFile=io.open(finFileNamePath,"r")
	
	if finFile~=nil then 
		io.close(finFile)
		ctagsLock=false
		os.remove(finFileNamePath)
		local fileNamePath= (props["project.ctags.propspath"])
		CTagsUpdateProps(true,fileNamePath)
		--print("...generating CTags finished",ctagsLock)		
	end
	finFile=nil

end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- RecreateCTags()
-- Search the File for new CTags and append them.
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CTagsRecreate()
	if  ctagsLock==true then return end	
	if props["project.name"]~="" and props["file.patterns.project"]:match(props["FileExt"])~=nil then
		ctagsBin=props["project.ctags.bin"]
		ctagsOpt=props["project.ctags.opt"]
		ctagsFP= props["project.ctags.filepath"]
		ctagsTMP="\""..os.getenv("tmp")..dirSep..props["project.name"]..".session.ctags\""

		os.remove(os.getenv("tmp")..dirSep.."*.session.ctags")
		if ctagsBin and ctagsOpt and ctagsFP then 
			ctagsCMD=ctagsBin.." -f "..ctagsTMP.." "..ctagsOpt.." "..props["FilePath"] 

			if props["project.ctags.save_applies"]=="1" then
				-- just do a full refresh to the project file in a background task
				ctagsCMD=ctagsBin.." -f "..ctagsFP.." "..ctagsOpt
				local pipe=scite_Popen(ctagsCMD)
				--local tmp= pipe:read('*a') -- synchronous -waits for the Command to complete
				-- periodically check if ctags refresh has been finished.
				scite_OnDwellStart(ProjectOnDwell)
				ctagsLock=true
			end
		end
	end	
		
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Registers the Autocomplete event Handlers early.
ProjectSetEnv(true)
