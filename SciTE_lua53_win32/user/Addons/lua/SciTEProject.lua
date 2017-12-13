
--
-- base Module, initialize Project Suport for SciTE
-- todo: implement IDM_RELOAD_PROPERTIES
--

local ctagsLock --true during writing to the projects ctags and properties files 

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
-- handle Project Folders (ctags, Autocomplete & highlitening)
--
--~~~~~~~~~~~~~~~~~~~
function HandleProject(init)
	if props["SciteDirectoryHome"] ~= props["FileDir"] then
		props["project.path"] = props["SciteDirectoryHome"]
		props["project.ctags.apipath"]=props["project.path"]..dirSep.."cTags.api"
		props["project.info"] = "{"..props["project.name"].."}->"..props["FileNameExt"]
		buffer.projectName= props["project.name"]
	else
		props["project.info"] =props["FileNameExt"] -- Display filename in StatusBar1
	end
 if init then dofile(myHome..'\\macros\\AutoComplete.lua') end
end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- UpdateProps()
-- publish cTag extrapolated Api Data -
-- reads cTag.properties
-- write them to SciTEs properties
-- probably should return something useful
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function UpdateProps()
	if ctagsLock==true or not props["project.path"] then return end	
	projectEXT="*.cxx"
	--props["file.patterns.project"]

	if file_exists(props["project.path"].."\\ctags.properties") then
		for entry in io.lines(props["project.path"].."\\ctags.properties") do
			prop,value=entry:match("([%w_]+)%s?=(.*)") 
			if prop=="cTagClasses" then props["substylewords.11.20."..projectEXT] = value end
			if prop=="cTagModules" then props["substylewords.11.18."..projectEXT] = value end
			if prop=="cTagFunctions" then props["substylewords.11.17."..projectEXT] = value end
			if prop=="cTagNames" then props["substylewords.11.16."..projectEXT]= value end      
			if prop=="cTagENUMs" then props["substylewords.11.19."..projectEXT]= value end             
			if prop=="cTagOthers" then props["substylewords.11.15."..projectEXT] = value end   
		end
	end
	
	local currentLexer=props["Language"]
	props["substyles."..currentLexer..".11"]=20

	props["style."..currentLexer..".11.15"]=props["colour.project.enums"]    
	props["style."..currentLexer..".11.16"]=props["colour.project.constants"]
	props["style."..currentLexer..".11.17"]=props["colour.project.functions"]
	props["style."..currentLexer..".11.18"]=props["colour.project.modules"]
	props["style."..currentLexer..".11.19"]=props["colour.project.enums"]
	props["style."..currentLexer..".11.20"]=props["colour.project.class"]
	
	scite.MenuCommand(IDM_SAVE)  -- reload props, todo: implement IDM_RELOAD_PROPERTIES

end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 
--ProjectOnDwell()
-- (.....)
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function ProjectOnDwell()
	if ctagsLock==false or not props["project.path"] then return end	

	--print("ProjectOnDwell: cTagsLock",ctagsLock,"inProject",inProject)	
	finFileNamePath=os.getenv("tmp")..dirSep.."project.ctags"..".fin"
	local finFile=io.open(finFileNamePath,"r")

	if finFile~=nil then 
		io.close(finFile)
		ctagsLock=false
	--	print("...generating CTags finished",ctagsLock) 
		os.remove(finFileNamePath)

		-- Append ctag APIdata Once to filetypes api path
		projectEXT="*.cxx"
		--props["file.patterns.project"]
	
	--print(props["colour.project.enums"] ,props["file.patterns.project"],props["APIPath"])
	--print(props["project.cTagFunctions"])

		--Now Expose the functions collected by cTags for syntax highlitening a Projects API      
		--todo use a nice Helper! 
		if origApiPath==nil then origApiPath=props["APIPath"] end
		props["api."..projectEXT] =origApiPath..";"..props["project.ctags.apipath"]
		UpdateProps()
	end
	finFile=nil

end

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- RecreateCTags()
-- Search the File for new CTags and append them.
--
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function RecreateCTags()
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
				-- also do a full refresh to the project file in a background task
				ctagsCMD=ctagsBin.." -f "..ctagsFP.." "..ctagsOpt
				local pipe=scite_Popen(ctagsCMD)
				--local tmp= pipe:read('*a') -- synchronous -waits for the Command to complete
				-- periodically check if ctags refresh has been finished.
				--scite_OnDwellStart(ProjectOnDwell)
				ctagsLock=true
			end
		end
	end	
		
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Registers the Autocomplete event Handlers early.
HandleProject(true)