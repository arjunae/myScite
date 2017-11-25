' Disclaimer
'--------------------------------------------------------------------------------- 
' The sample scripts are not supported under any Microsoft standard support 
' program or service. The sample scripts are provided AS IS without warranty  
' of any kind. Microsoft further disclaims all implied warranties including,  
' without limitation, any implied warranties of merchantability or of fitness for 
' a particular purpose. The entire risk arising out of the use or performance of  
' the sample scripts and documentation remains with you. In no event shall 
' Microsoft, its authors, or anyone else involved in the creation, production, or 
' delivery of the scripts be liable for any damages whatsoever (including, 
' without limitation, damages for loss of business profits, business interruption, 
' loss of business information, or other pecuniary loss) arising out of the use 
' of or inability to use the sample scripts or documentation, even if Microsoft 
' has been advised of the possibility of such damages 
'--------------------------------------------------------------------------------- 

' Objective
'===================================================================
' This sample VBScript is for resetting file association
' It selects Word application as the default editor for .doc files
' The default application actually updated in the corresponding registry key of the .ext under HKEY_CLASSES_ROOT
' The default value of the registry key corresponds to the default application
' This script uses StdRegProv WMI class to modify registry key 
' Refer the below link for StdRegProv WMI class
' http://msdn.microsoft.com/en-us/library/windows/desktop/aa393664(v=vs.85).aspx 
'===================================================================

' registry subtree HKEY_CLASSES_ROOT 
' http://technet.microsoft.com/en-us/library/cc739822(v=WS.10).aspx
Const HKEY_CLASSES_ROOT              = &H80000000
Dim iKeyExist
Dim strComputer
Dim objReg

' Computer name to be connected - '.' refers to the local machine
strComputer = "."

' Initialize WMI service and connect to the class StdRegProv
' Refer 'http://msdn.microsoft.com/en-us/library/windows/desktop/aa394525(v=vs.85).aspx' for winmgmt
Set objReg=GetObject("winmgmts:\\"& strComputer & "\root\default:StdRegProv")

' cross check for the existance of required .ext under HKEY_CLASSES_ROOT
iKeyExist = objReg.EnumKey(HKEY_CLASSES_ROOT, ".doc", arrSubkeys) 

' iKeyExist value 0 confirms the existance
If iKeyExist = 0 Then
		' Default key of a registry key is string type - REG_SZ
		' Link for SetStringValue method - http://msdn.microsoft.com/en-us/library/windows/desktop/aa393600(v=vs.85).aspx
		objReg.setStringValue HKEY_CLASSES_ROOT,".doc","","Word.Document.8"
		' A message box to confirm the modification
		MsgBox("Set the file association for .doc to Worp Processor!")
End If

' Quit VBScript
WSCript.Quit(0)
