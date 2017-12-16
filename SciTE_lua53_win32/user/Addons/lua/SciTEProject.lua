--
-- SciTEProject.lua, base Module: initialize Project and CTags Support for mySciTE.
-- License: BSD3Clause. Author Thorsten Kani
-- Version: 0.8
-- todo: test implementation scite.ReadProperties
--

local ctagsLock --true during writing to the projects ctags and properties files 

--~~~~~~~~~~~~~~~~~~~
--
-- NameCache
--
--~~~~~~~~~~~~~~~~~~~
local cTagNames
local cTagClasses
local cTagModules
local cTagFunctions
local cTagNames
local cTagENUMs
local cTagOthers
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
local function ProjectSetEnv(init)

	if props["SciteDirectoryHome"] ~= props["FileDir"] then
		props["project.path"] = props["SciteDirectoryHome"]
		props["project.ctags.filename"]="ctags.tags"
		props["project.ctags.apipath"]=props["project.path"]..dirSep..props["project.ctags.filename"]..".api"
		props["project.ctags.propspath"]=props["project.path"]..dirSep..props["project.ctags.filename"]..".properties"
		props["project.info"] = "{"..props["project.name"].."}->"..props["FileNameExt"]
		buffer.projectName= props["project.name"]
	else
		props["project.info"] =props["FileNameExt"] -- Display filename in StatusBar1
	end
	
	if init then dofile(myHome..'\\macros\\AutoComplete.lua') end

end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- UpdateProps() / publish cTag extrapolated Api Data -
-- reads cTag.properties and writes them to SciTEs .api and .properties files.
-- returns cTagList, which contains a List of all Names found in the tagFile
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CTagsUpdateProps(theForceMightBeWithYou)
local appendMode=true

	ProjectSetEnv(false)
	local prefix=props["project.ctags.filename"]
	if not string.find(prefix,"append") then
		cTagNames="" cTagClasses="" cTagModules="" cTagFunctions="" cTagNames="" cTagENUMs="" cTagOthers=""
		appendMode=false
	end
	
	if ctagsLock==true or  props["project.path"]=="" then return end	
	projectEXT=props["file.patterns.project"]
	
	-- Propagate the Data, appends if required
	if file_exists(props["project.ctags.propspath"]) and (not cTagList or appendMode) or (theForceMightBeWithYou==true) then
	cTagList={}
		for entry in io.lines(props["project.ctags.propspath"]) do
			prop,names=entry:match("([%w_.]+)%s?=(.*)") 
			if prop==prefix..".cTagClasses" then cTagClasses= cTagClasses.." "..names  end
			if prop==prefix..".cTagModules" then cTagModules = cTagModules.." "..names end
			if prop==prefix..".cTagFunctions" then cTagFunctions = cTagFunctions.." "..names end
			if prop==prefix..".cTagNames" then cTagNames= cTagNames.." "..names end
			if prop==prefix..".cTagENUMs" then cTagENUMs= cTagENUMs.." "..names end
			if prop==prefix..".cTagOthers" then cTagOthers =cTagOthers.." "..names end
			--- concatenate all entries in the current list.
			for i in string.gmatch(names, "%S+") do
				cTagList[i]=true
			end
		end

		--write properties to Scites Config.
		props["substylewords.11.20."..projectEXT] = cTagClasses
		props["substylewords.11.18."..projectEXT] = cTagModules
		props["substylewords.11.17."..projectEXT] = cTagFunctions
		props["substylewords.11.16."..projectEXT]= cTagNames
		props["substylewords.11.19."..projectEXT]= cTagENUMs
		props["substylewords.11.15."..projectEXT] = cTagOthers

		--Update filetypes api path.  Append only Once
		local origApiPath
		if props["project.path"]~="" then
        if origApiPath==nil then 
            origApiPath=props["APIPath"]
            props["api."..props["file.patterns.project"]] =origApiPath..";"..props["project.ctags.apipath"] 
        end
    end
	end
	
	-- Define the Styles for aboves types
	local currentLexer=props["Language"]
	props["substyles."..currentLexer..".11"]=20

	props["style."..currentLexer..".11.15"]=props["colour.project.enums"]    
	props["style."..currentLexer..".11.16"]=props["colour.project.constants"]
	props["style."..currentLexer..".11.17"]=props["colour.project.functions"]
	props["style."..currentLexer..".11.18"]=props["colour.project.modules"]
	props["style."..currentLexer..".11.19"]=props["colour.project.enums"]
	props["style."..currentLexer..".11.20"]=props["colour.project.class"]
	
	if theForceMightBeWithYou==true then scite.ApplyProperties() end
	
	return cTagList
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
		if file_exists(props["project.ctags.propspath"]) then CTagsUpdateProps(true) end
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