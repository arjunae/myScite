' Objective
'===================================================================
' This sample VBScript is for (re)setting file associations for SciTE
' This script uses StdRegProv WMI class to modify registry key 
' Refer the below link for StdRegProv WMI class
' https://msdn.microsoft.com/en-us/library/aa393664(VS.85).aspx 
'===================================================================
Const HKEY_CLASSES_ROOT	= &H80000000
Const HKEY_CURRENT_USER	= &H80000001
Const HKEY_LOCAL_MACHINE	= &H80000002
Const HKEY_USERS								= &H80000003

Const REG_SZ							= 1
Const REG_EXPAND_SZ	= 2
Const REG_BINARY				= 3
Const REG_DWORD				= 4
Const REG_MULTI_SZ		= 7
Const FILE_EXT_PATH	= "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\"

Dim cntExt ' Script returns the number of written fileExts.

Set oFso = CreateObject("scripting.FilesystemObject")
Set oFileExt = oFso.OpenTextFile("scite_filetypes.txt", 1, True) ' forRead, CreateFlag
if  isNull(oFileExt) then Wscript.echo("scite_filetypes.txt no found") 
startMark=0
    
while Not oFileExt.AtEndOfStream
dim strExt, startMark,arrExt
    sChar = oFileExt.Read(1)
    if sChar="#" Then oFileExt.SkipLine ' Comment
    
    if  sChar=vbCR or sChar=vbLF  then 
      oFileExt.SkipLine()
      'strDesc=Replace(strDesc,"=","")
      strExt=Replace(strExt,"*","")
      strExt=Replace(strExt,vbCR,"") 'Just in case someone onverted the file to be UNiX Formatted
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
result=256

  ' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
  ' Returns: 0==KeyExist, 2==KeyNotExist 
  iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys) 
  
   'result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt)
   
  ' Create it if it does not exist
  ' CreateKey Method -
  'if iKeyExist = 2 and Err.Number = 0 Then	
   result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt)
   result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithList")
   result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithProgIDs")
  'end if

  ' Modify the Key
  ' SetStringValue Method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
  if Err.Number = 0 then	
  
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","a","{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\OpenWith.exe")  
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","y","SciTE.exe")
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","MRUList","ya")
  result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgIDs","Applications\Scite.exe","")
         
  End If
  'wscript.Echo(Err.Number & " " & result)

 if result=0 and Err.Number = 0 and result= 0 then 
 assoc_ext_with_scite=0
'  wscript.echo("Created / Modified fileExt " & fileExt )
 else
  assoc_ext_with_scite=2
 end if
end function

