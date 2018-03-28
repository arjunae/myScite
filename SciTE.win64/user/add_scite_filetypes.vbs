' Objective
'======================================================
' This sample VBScript is for (re)setting file associations for SciTE
' Just writes itself at the end of suggested Apps in the "open File" Dialogue.
' so former choosen Apps keep their precedence until the User chooses otherwise.
'
' Refer the below link for StdRegProv WMI class
' https://msdn.microsoft.com/en-us/library/aa393664(VS.85).aspx 
'=======================================================
Const HKEY_CLASSES_ROOT	= &H80000000
Const HKEY_CURRENT_USER	= &H80000001
Const HKEY_LOCAL_MACHINE	= &H80000002
Const HKEY_USERS								= &H80000003

' Much depreceated Information in the Net, even from MS  still refers to use machine wide HKCR for file Exts.
' But modifying that mostly needs root privs to change and myScite has dropped to be XP Compatible for a while now. 
' So we rely to use HKCU to reach our goals  and dont require admi privs - since we only touch stuff within our own User profile.

Const FILE_EXT_PATH	= "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\"
Dim cntExt ' Script returns the number of written fileExts.

' Open myScites known filetype List.
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
       
      ' Remove trash from the result
      strDesc=Replace(strDesc,"=","")
      strExt=Replace(strExt,"*","")
      strExt=Replace(strExt,vbCR,"")

      ' Create an Array from the gathered Stuff.
      ' Iterate through and register each filetype. 
      arrExt =split(strExt,";")
      for each strEle in arrExt
        if left(strEle,1)="." then
         cntExt=CntExt+1         
         result= assoc_ext_with_scite(strEle)
        end if
      next
     
     startMark=0 : strDesc="" :strExt="":strEle=""
    end if
  
    if startMark=0 then
      strDesc=strDesc+sChar
    else
      strExt=strExt+sChar
    end if 
    
    if sChar="=" Then startMark=1
wend

oFileExt.close()
'MsgBox("Status:" & cntExt & "Einträge verarbeitet" )

WScript.Quit(cntExt)


' ~~~~ Functions
 
private function assoc_ext_with_scite(fileExt) 

' VbScript WTF.. If you init that object only once for reusal, its creating unpredictable entries within the registry...
' Took me the half the day to get to that perfectly "amusing" Fact 
Dim objReg ' Initialize WMI service and connect to the class StdRegProv
strComputer = "." ' Computer name to be connected - '.' refers to the local machine
Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

Dim iKeyExist
Dim strComputer

  ' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
  ' Returns: 0==KeyExist, 2==KeyNotExist 
  iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys) 
  
   'result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt)
   
  ' Create it if it does not exist
  ' CreateKey Method -
  if iKeyExist = 2 and Err.Number = 0 Then	
   result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt)
   result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithList")
   result = result + objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithProgIDs")
  end if

  ' Modify the Key
  ' SetStringValue Method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
  if Err.Number = 0 then	
   result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","a","{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\OpenWith.exe")  
   result = result +  objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","y","SciTE.exe")
   result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","MRUList","ya")
   result = result + objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgIDs","Applications\Scite.exe","")
  End If
  
  ' Above Stuff returns Zero on success.
  ' if anything gone wrong, we will see that here:
  'wscript.Echo(Err.Number & " " & result)

 if result=0 and Err.Number = 0 then 
 assoc_ext_with_scite=0
'  wscript.echo("Created / Modified fileExt " & fileExt )
 else
  assoc_ext_with_scite=2
 end if
end function

