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


' todo ->parse scite_filetypes.txt here!
result= assoc_ext_with_scite(".009")
'MsgBox("Status " & result )

WScript.Quit(result)

' ~~~~ Functions
 
private function assoc_ext_with_scite(fileExt) 

Dim iKeyExist
Dim strComputer
result=256

  ' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
  ' Returns: 0==KeyExist, 2==KeyNotExist 
  iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys) 

  ' Create it if it does not exist
  ' CreateKey Method -
  if iKeyExist = 2 and Err.Number = 0 Then	
   result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithList")
  end if

  ' Modify the Key
  ' SetStringValue Method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
  if Err.Number = 0 then	
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","a","SciTE.exe")
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","MRUList","a")
   
   ' Now set the DefaultApp
   result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgids")
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgids","Applications\scite.exe","")
   
   ' And reset the former UserChoice
  ' result = objReg.DeleteKEy(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\UserChoice")
  ' result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\UserChoice")
  ' result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\UserChoice","ProgId", "Applications\scite.exe")
  ' result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\UserChoice","Hash", "sJ0wxtHNf28=")
  End If
  'wscript.Echo(Err.Number & " " & result)

 if result=0 and Err.Number = 0 and result= 0 then 
 assoc_ext_with_scite=0
  MsgBox("Created / Modified fileExt " & fileExt )
 else
  assoc_ext_with_scite=2
 end if
  
end function

