' Objective
'===================================================================
' This sample VBScript is for resetting file association
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

Dim objReg ' Initialize WMI service and connect to the class StdRegProv
strComputer = "." ' Computer name to be connected - '.' refers to the local machine
Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")


Dim cntExt ' Script returns the number of written fileExts.

Set oFso = CreateObject("scripting.FilesystemObject")
Set oFileExt = oFso.OpenTextFile("scite_filetypes.txt", 1, True) ' forRead, CreateFlag
if  isNull(oFileExt) then Wscript.echo("scite_filetypes.txt no found") 
starMark=0

while Not oFileExt.AtEndOfStream
    dim strExt, startMark,arrExt
    
    sChar = oFileExt.Read(1)
    if sChar="#" Then oFileExt.SkipLine ' Comment
    
    if sChar=vbCrLF or sChar=vbLF  then 
      oFileExt.SkipLine()
      
      'strDesc=Replace(strDesc,"=","")
      'wscript.echo(strDesc)
      'wscript.echo(strExt)

      arrExt =split(Replace(strExt,"*",""),";")
      for each strEle in arrExt
        if left(strEle,1)="." then
         cntExt=CntExt+1
         result= assoc_ext_with_scite(strEle)
        end if
      next
     
      startMark=0 : strDesc="" : strExt=""
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

'Writing Fileextensions that way requires the Association to be already created ?!
'So that fuckn VBScript-WMI Shit -- Simply doesnt do the trick where it should when belevin the docs
'When i calmed down - that mud will be converted into a simple but "provenToWork(tm)" registry import file....

Dim iKeyExist
Dim strComputer
result=256

  ' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
  ' Returns: 0==KeyExist, 2==KeyNotExist 
  iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys) 

  ' Create it if it does not exist
  ' CreateKey Method -
  if iKeyExist = 2 and Err.Number = 0 Then	
  ' result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithList")
  end if

  ' Modify the Key
  ' SetStringValue Method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
  if Err.Number = 0 then	
  
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","a","{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\OpenWith.exe")  
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","y","SciTE.exe")
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","MRUList","ya")
   
   ' Now set the DefaultApp
   'result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgids")
   'result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgids","Applications\scite.exe","")

  ' set oshell = createobject("Wscript.Shell")
  'Name = "Applications\Scite.exe"
  'oShell.Run "reg add HKCU\" & FILE_EXT_PATH & fileExt & "\OpenWithProgids\ /v " & Chr(34) & Name & Chr(34) ,0 

     
  End If
  'wscript.Echo(Err.Number & " " & result)

 if result=0 and Err.Number = 0 and result= 0 then 
 assoc_ext_with_scite=0
'  wscript.echo("Created / Modified fileExt " & fileExt )
 else
  assoc_ext_with_scite=2
 end if
  
end function

