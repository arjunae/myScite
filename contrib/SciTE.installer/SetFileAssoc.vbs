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

Dim iKeyExist
Dim strComputer
Dim objReg
Dim fileExt

strComputer = "." ' Computer name to be connected - '.' refers to the local machine
fileExt=".000"

' Initialize WMI service and connect to the class StdRegProv
Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
' Returns: 0==KeyExist, 2==KeyNotExist 
iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, "Software\Classes\" & fileExt, arrSubkeys) 

' Modify the Key or Create it if it does not exist
If iKeyExist = 0 and Err.Number = 0 Then
	' SetStringValue method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx		
	result=objReg.setStringValue(HKEY_CURRENT_USER, "Software\Classes\" & fileExt,"SciTE")
elseif iKeyExist= 2 and Err.Number = 0 then
	result = objReg.CreateKey(HKEY_CURRENT_USER, "Software\Classes\" & fileExt)		
End If

MsgBox(Err.Number & ",," & result)

WScript.Quit(0)
