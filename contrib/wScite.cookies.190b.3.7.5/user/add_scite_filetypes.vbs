 ' Objective
 '======================================================
 ' This sample VBScript is for (re)setting file associations for SciTE
 ' Just writes itself at the end of suggested Apps in the "open File" Dialogue.
 ' so former choosen Apps keep their precedence until the User chooses otherwise.
 '
 ' written in "WonderFull" vbs - as Powershell is really bloaty.
 ' Refer the below link for StdRegProv WMI class
 ' https://msdn.microsoft.com/en-us/library/aa393664(VS.85).aspx 
 '=======================================================
 Const HKEY_CLASSES_ROOT	= &H80000000
 Const HKEY_CURRENT_USER	= &H80000001
 Const HKEY_LOCAL_MACHINE	= &H80000002
 Const HKEY_USERS								= &H80000003

 ' Ther's much depreceated Information in the Net, even from MS which still refers to use machine wide HKCR for file Exts.
 ' But modifying that mostly needs root privs to change and myScite has dropped to be XP Compatible for a while now. 
 ' So we rely to use HKCU to reach our goals  and dont require admin privs - since we only touch stuff within our own User profile.

 Const FILE_EXT_PATH	= "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\"
 Const FILE_EXT_PATH_CLS	= "Software\Microsoft\Classes\"

 if instr(1,wscript.fullName,"cscript") then bConsole=true

 function main()
  Dim cntExt ' contains the number of written fileExts.
  Dim cntTyp ' contains the number of parsed myScite fileTypes

  ' Open myScites known filetypes List.
  Set oFso = CreateObject("scripting.FilesystemObject")
  Set oFileExt = oFso.OpenTextFile("scite_filetypes.txt", 1, True) ' forRead, CreateFlag
  if  isNull(oFileExt) then Wscript.echo("scite_filetypes.txt not found") 

  ' Iterate through. Treat lines beginning with # as a comment. 
  while Not oFileExt.AtEndOfStream
   dim strExt, startMark,arrExt

   sChar = oFileExt.Read(1)
   if sChar="#" Then oFileExt.SkipLine ' Comment
   
   ' Just in case someone edited the file to be partly UNiX Formatted
   if  sChar=vbCR or sChar=vbLF  then 
     oFileExt.SkipLine()
     cntTyp=cntTyp+1
     
     ' Remove trash from the result
     strDesc=Replace(strDesc,"=","")
     strExt=Replace(strExt,"*","")
     strExt=Replace(strExt,vbCR,"")
     
     'if bConsole then wscript.echo(" ..Registering: " & strDesc)
     ' Create an Array from the gathered Stuff.
     ' Iterate through and register each filetype. 
     arrExt=split(strExt,";")
     for each strEle in arrExt
       if left(strEle,1)="." then
        cntExt=cntExt+1         
        result=assoc_ext_with_scite(strEle)
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

  oFileExt.close()
  'MsgBox("Status:" & cntExt & "Einträge verarbeitet" )
  main=cntTyp
 end function


 ' ~~~~ Functions
  
 private function assoc_ext_with_scite(fileExt) 

 ' VbScript WTF.. If you init that object below only once for reusal, its creating unpredictable entries within the registry...
 ' Took me half the day to get to that "perfectly amusing" Fact. 
 
 Dim objReg ' Initialize WMI service and connect to the class StdRegProv
 strComputer = "." ' Computer name to be connected - '.' refers to the local machine
 Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

 Dim iKeyExist
 Dim strComputer
 Dim autofileExt

   autofileExt=replace(fileExt,".","") & "_auto_file"   
  
   ' ... yodaForce ...
   ' handle eventually defect Entries by starting Clean with every not currently used handler resetted.
 
   ' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
   ' Returns: 0==KeyExist, 2==KeyNotExist 
   iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\UserChoice"	, arrSubkeys)   
  
   ' Dont reset the ext if a user already selected a program to handle that. 
   ' DeleteKey cant handle recursion itself, so put a little wrapper around:
		if iKeyExist = 2 and Err.Number = 0 Then  
     ' Reset the ext in currentUser\...\Explorer
			result= objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys)   
			if result=0 then 
        for each subKey in arrSubKeys
           'if bConsole then wscript.echo("Removed:" & "HKCU\" & FILE_EXT_PATH & fileext & "\" &subKey)
          result= objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH &  subKey)   			
        next
      end if

      ' Also reset that fileExt within currentUser\Applications
      result = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS & fileExt	, arrSubkeys)   
      if result=0 then 
        for each subKey in arrSubKeys
           'if bConsole then wscript.echo("Removed:" & "HKCU\" & FILE_EXT_PATH_CLS & fileext & "\" &subKey)
          result= objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS &  subKey)   			
        next
      end if
		end if
  
   ' ...Key (re)creation starts here....
   
   iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgIDs"	, arrSubkeys) 
        
   ' Create it if it does not exist
   ' CreateKey Method - https://msdn.microsoft.com/en-us/library/aa389385(v=vs.85).aspx
   if iKeyExist = 2 and Err.Number = 0 Then	
    result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt)
    result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithList")
    result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithProgIDs")
   end if

   ' Modify the Key
   ' SetStringValue Method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
   if result=0 and Err.Number = 0 then	
   '1AC14E77-02E7-4E5D-B744-2EB1AE5198B7 is the UUID equivalent for %systemroot%\system32
    result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","a","{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\OpenWith.exe")  
    result = result +  objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","y","SciTE.exe")
    result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","MRUList","ya")
    result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgIDs","Applications\Scite.exe","")
   End If

   ' Above Stuff returns Zero on success.
   ' if anything gone wrong, we will see that here:
   'wscript.Echo("Status: Error? " & Err.Number & " resultCode? " & result)

   if result=0 and Err.Number = 0 then 
    assoc_ext_with_scite=0
    if bConsole then wscript.echo("Created / Modified fileExt " & fileExt )
   else
    assoc_ext_with_scite=2
   end if
 end function

 wscript.quit(main)