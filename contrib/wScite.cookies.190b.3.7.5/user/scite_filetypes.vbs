' Objective
'======================================================
'
' This VBScript is for (re)setting file associations for SciTE
' Just writes itself at the end of suggested Apps in the "open File" Dialogue
' so former choosen Apps keep their precedence until the User chooses otherwise.
'
' Written in heavenly "WonderFull" vbs - as i do think that Powershell is really bloaty.
' Refer the below link for StdRegProv WMI class
' https://msdn.microsoft.com/en-us/library/aa393664(VS.85).aspx 
'
' v0.8 -> Add backup capabilities  - Initial public release. 
'
' Mar2018 / Marcedo@habMalNeFrage.de
' License BSD-3-Clause
' Version: 0.8 - To test --> start within a "test" UserProfile <---
'=======================================================
Const HKEY_CLASSES_ROOT  = &H80000000
Const HKEY_CURRENT_USER  = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS               = &H80000003
Const APP_NAME                 = "SciTE.exe"
Const APP_DATA                 = "scite_filetypes.txt"
Const ERR_WARN		= 966
Const ERR_FATAL	= 969
Const ERR_OK	= 0

' Ther's much depreceated Information in the Net, even from MS which still refers to use machine wide HKCR for file Exts.
' But modifying that mostly needs root privs when changed and myScite has dropped to be XP Compatible for a while now. 
' So we rely to use HKCU to reach our goals - and dont require admin privs - since we only touch stuff within our own User profile.

Const FILE_EXT_PATH	= "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\"
Const FILE_EXT_PATH_CLS	= "Software\Classes\"
Const PROG_PATH= "Software\Classes\Applications\"

if instr(1,wscript.fullName,"cscript") then bConsole=true

function main()

Const REG_HEADER = "Windows Registry Editor Version 5.00"
Dim arg0 ' either not given or any of the verbs install / uninstall
Dim action ' currently - 10 for uninstall or 11 for install
Dim cntExt ' contains the number of written strFileExts.
Dim cntTyp ' contains the number of parsed myScite fileTypes
Dim clearCmds, strExtKey ' clearCmd means a prefixed "-" followed by the Registry Key to be removed.
Dim arrAllExts() 'Array containing every installer touched Ext

	if WScript.Arguments.count > 0 then arg0 = WScript.Arguments.Item(0)

	if LCase(arg0)="uninstall" then
		if bConsole then wscript.echo(" We do an -UNInstall- ") 
		action = 10 
	elseif LCase(arg0)="install" then  
		if bConsole then wscript.echo(" We do an -Install- ")
		action = 11
	else
		if bConsole then wscript.echo(" Defaulting to action -Install- ")
		action = 11
	end if

	' Open myScites known filetypes List using vbscripts funny sortof a "catchme if you can" block.
	on error resume next 
		Set oFso = CreateObject("scripting.FilesystemObject")
		Set oFileExt = oFso.OpenTextFile("scite_filetypes.txt", 1, False) ' forRead, CreateFlag
		if typename(oFileExt)="Empty" then
			Wscript.echo("... " & APP_DATA & " not found") 
			exit function
		end if
	on error goto 0

	'	todo: think about a performant filter matching only Installer touched instead of All Entries. 	
	' a custom RegistryDump Func instead of reg.exe would do, but that would be slightly overdressed here.		
	' so for now: create a full backup of all Exts in Explorer\fileExts during install.
	if action = 11 then 
		strRootExt="HKEY_CURRENT_USER\" & FILE_EXT_PATH  
		Set objShell = CreateObject("WScript.Shell")	
		objShell.exec("REG.EXE EXPORT " & strRootExt & " " & "tmp_backup.reg")
		clearCmds=clearCmds & REG_HEADER
		if bConsole then wscript.echo(" ..Initialized the Backup File")
	end if
	
	' Iterate through the DataFile Treat lines beginning with # as a comment. 
	while Not oFileExt.AtEndOfStream
		dim strExt, startMark,arrExt

		sChar = oFileExt.Read(1)
		if sChar="#" Then oFileExt.SkipLine ' Comment

		' Just in case someone edited the file to be partly UNiX Formatted
		if sChar=vbCR or sChar=vbLF  then 
		oFileExt.SkipLine()
		cntTyp=cntTyp+1

		' Remove trash from the result
		strExt=Replace(strExt,"*","")
		strExt=Replace(strExt,vbCR,"")
		strDesc=Replace(strDesc,"=","")
		
		' Create an Array from the gathered Stuff  
		' if bConsole then wscript.echo(" ..Registering: " & strDesc & " " & cntTyp)
		arrEntryExts=split(strExt,";")
		
		' Iterate through and register each filetype.
		for each strEle in arrEntryExts
			if left(strEle,1)="." then
				cntExt=cntExt+1 
				
				' Append to allExts for Restore File
				redim preserve arrAllExts(cntExt)
				arrAllExts(cntExt)=strEle
				
				' Write reset Cmds for the restore file
				strExtKey="HKEY_CURRENT_USER\" & FILE_EXT_PATH & strEle  
				clearCmds=clearCmds & vbCrLf & "-[" & strExtKey & "]"
				
				' Continue with the desired action:
				if action=11 then result=assoc_ext_with_program(strEle)
				if action=10 then result=unassoc_ext_with_program(strEle)				
				
				'  .. todo- implement an more sophisticated Error Handling...
				if result=ERR_WARN then 
					if bconsole then wscript.echo("-- Warn: Your fileExt [" &  strEle &"] doesnt like our Tardis ?!" ) 
				elseif result=ERR_FATAL then ' Fatallity...Grab your Cat and run like Hell....
					wscript.echo("-- Fatal: Universum Error. -Stop-")
					return(result)
				end if
			end if
		next

		startMark=0 : strDesc="" :strExt="":strEle=""
		end if

		if startMark=0 then
			strDesc=strDesc+sChar
		else
			strExt=strExt+sChar
		end if 

		if sChar= "=" Then startMark=1
	wend

	if action = 11 then ' Merge Data to extRestore.reg
		' Open tmp_backup.reg file
		set oFile1= oFso.GetFile("tmp_backup.reg")
		Set oFileTmp1 = oFile1.OpenAsTextStream(1, -1) ' forRead, ForceUnicode	

		' Write the restore.reg file
		' If we wanted to, we were also able to write it in Unicode. But then the file would have its size doubled.
		Set oFileTmp2 = oFso.OpenTextFile("extRestore.reg",2, 1) ' forWrite, createFlag	
		oFileTmp2.write(clearCmds)
		while not  oFileTmp1.AtEndOfStream
			strEntry=oFileTmp1.ReadLine()
			oFileTmp2.write(vbcrlf & strEntry)
		'	oFileTmp2.write(vbCrLf & filterOwn(arrAllExts,strEntry))
			wend
		oFileTmp1.close()
		oFileTmp2.close()
		oFso.DeleteFile("tmp_backup.reg")
	end if
	
	oFileExt.close()
	'MsgBox("Status:" & cntExt & "Einträge verarbeitet" )
	main=cntTyp
end function


' ~~~~ Functions ~~~~~

private function ClearKey(objReg, iRootKey, strRegKey)
'
' DeleteKey cant handle recursion itself so put a little wrapper around:
' (Only Delete the SubKeys, dont Delete the Key itself) 
'
dim iKeyExist, arrSubkeys
	if strRegKey="" then exit Function
	iKeyExist = objReg.EnumKey(iRootKey , strRegKey	, arrSubkeys)   
	if typeName(arrSubkeys) = "Null" then exit function
	if iKeyExist>0  then exit function
	for each strSubKey in arrSubKeys
		'if bConsole then wscript.echo("Removed: " & strRegKey & "\" & strSubKey)
		ClearKey= objReg.DeleteKey(iRootKey , strRegKey & "\" & strSubKey)   			
	next  
end function

' ~~~~~~~~~~~~~~~~~~~~~~

' VbScript WTF.. If you init that objReg only once for reusal in globalSope, its creating unpredictable entries within the registry...
' Took me half the day to get to that "perfectly amusing" Fact. 

private function assoc_ext_with_program(strFileExt) 
'
' Registers all mySciTE known Filetypes
'

'todo - handle special: .bas .hta .js .msi .ps1 .reg .vb .vbs .wsf in Key UseLocalMachineSoftwareClassesWhenImpersonating
'Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileAssociation

Dim iKeyExist, strComputer, autofileExt
Dim objReg ' Initialize WMI service and connect to the class StdRegProv
	strComputer = "." ' Computer name to be connected - '.' refers to the local machine
	Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
	
	autofileExt=replace(strFileExt,".","") & "_auto_file"   

	' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
	' Returns: 0==KeyExist, 2==KeyNotExist 

	' First - force Progs Application Key to be defined properly:
	iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, PROG_PATH & APP_NAME, arrSubkeys)   
	if iKeyExist >0 then
		wscript.echo(" Please run through .installer.cmd")
		assoc_ext_with_program=ERR_FATAL
		exit function
	end if

	' ... yodaForce ...
	' handle eventually defect Entries by starting Clean with every not currently used handler resetted.

	iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & strFileExt & "\UserChoice", arrSubkeys)   

	' Dont reset the ext if a user already selected a program to handle it. (Key UserChoice exists) 
	if iKeyExist = 2 and Err.Number = 0 Then 
		' Clear the strFileExt in currentUser\....\strFileExts
		result=ClearKey(objReg,HKEY_CURRENT_USER , FILE_EXT_PATH & strFileExt)
		' Also Clear the strFileExt within currentUser\Applications
		result=ClearKey(objReg,HKEY_CURRENT_USER ,  FILE_EXT_PATH_CLS &  autofileExt)
		' Optional: Clear the autoFileExt within Depreceated HKCR - needs rootPrivs on most modern systems, so is likely to fail.
		blabla=ClearKey(objReg,HKEY_CLASSES_ROOT ,  autoFileExt)
	end if

	' ...Key (re)creation starts here....
	iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & strFileExt & "\OpenWithProgIDs", arrSubkeys) 

	' Create it if it does not exist
	' CreateKey Method - https://msdn.microsoft.com/en-us/library/aa389385(v=vs.85).aspx
	if iKeyExist = 2 and Err.Number = 0 Then	
		result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & strFileExt)
		result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & strFileExt & "\OpenWithList")
		result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & strFileExt & "\OpenWithProgIDs")
	end if

	' Modify the Key
	' SetStringValue Method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
	if result=0 and Err.Number = 0 then	
		'1AC14E77-02E7-4E5D-B744-2EB1AE5198B7 is just the UUID equivalent for %systemroot%\system32
		result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & strFileExt & "\OpenWithList","a","{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\OpenWith.exe")  
		result = result +  objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & strFileExt & "\OpenWithList","y",APP_NAME)
		result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & strFileExt & "\OpenWithList","MRUList","ya")
		result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & strFileExt & "\OpenWithProgIDs","Applications\" & APP_NAME,"")
	End If

	' Above Stuff returns Zero on success.
	' if anything gone wrong, we will see that here:
	'wscript.Echo("Status: Error? " & Err.Number & " resultCode? " & result)

	if result=0 and Err.Number = 0 then 
		assoc_ext_with_program=ERR_OK
		'if bConsole then wscript.echo("Created / Modified strFileExt " & strFileExt )
	else
		assoc_ext_with_program=ERR_WARN
	end if

	set objReg=Nothing
end function

'~~~~~~~~~~~~

private function unassoc_ext_with_program(strFileExt)
'
' removes scite related subkeys in HKCU..Explorer\FileExts and HKCU\Software\Classes
' which will cause Explorer to show the openFileWith Handler again.
'

Dim objReg ' Initialize WMI service and connect to the class StdRegProv
Dim arrKey,arrTypes, autofileExt

	autofileExt=replace(strFileExt,".","") & "_auto_file"   
	strComputer = "." ' Computer name to be connected - '.' refers to the local machine
	Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

	' a) ...we remove the reference to SciTE in OpenWithProgIDs 
	result = objReg.DeleteValue(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS &  strFileExt & "\OpenWithProgIDs", "Applications\" & APP_NAME)
	result = objReg.DeleteValue(HKEY_CURRENT_USER, FILE_EXT_PATH &  strFileExt & "\OpenWithProgIDs", "Applications\"& APP_NAME)
	' ... and clear an maybe existing auto_file entry
	result=objReg.GetStringValue (HKEY_CURRENT_USER, FILE_EXT_PATH_CLS & autofileExt & "\shell\Open\" ,"command" , strValue)
	if instr(lcase(strValue), lcase(APP_NAME)) then
		result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS & autofileExt & "\shell\Open\command")   			
	end if

	' b) ...we iterate through OpenWithLists ValueNames  
	result=objReg.EnumValues(HKEY_CURRENT_USER, FILE_EXT_PATH &  strFileExt & "\OpenWithList",arrKey,arrTypes)
	if typeName(arrKey) <> "Null" then
		do while icnt<=ubound(arrKey)
			result=objReg.GetStringValue (HKEY_CURRENT_USER, FILE_EXT_PATH &  strFileExt & "\OpenWithList" , arrkey(icnt), strValue)
			' c) ..Remove any Name which value refers to SciTE
			if instr(lcase(strValue), lcase(APP_NAME)) then
				result = objReg.DeleteValue(HKEY_CURRENT_USER, FILE_EXT_PATH &  strFileExt & "\OpenWithList", arrKey(icnt))
			end if
		icnt=icnt+1
		loop
		' d) ..Clear the UserChoice
		result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH &  strFileExt & "\UserChoice")
	end if

	if (result=0 or result=2) and Err.Number = 0 then 
		unassoc_ext_with_program=ERR_OK
		'if bConsole then wscript.echo("Modified strFileExt " & strFileExt )
	else
		unassoc_ext_with_program=ERR_WARN
	end if

	set objReg=Nothing
end function

' ~~~~~~~~	

wscript.quit(main)
