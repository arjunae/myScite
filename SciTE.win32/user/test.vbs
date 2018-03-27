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

fileExt=".ino"
Dim objReg ' Initialize WMI service and connect to the class StdRegProv
strComputer = "." ' Computer name to be connected - '.' refers to the local machine
Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
dim iKeyExist
iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys) 
wscript.echo(iKeyExist)
' enumKey Method: https://msdn.microsoft.com/de-de/library/windows/desktop/aa390387(v=vs.85).aspx
  ' Returns: 0==KeyExist, 2==KeyNotExist 
  result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt)
	
	iKeyExist = objReg.EnumKey(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt	, arrSubkeys) 
	result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithList")
	
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","a","{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\OpenWith.exe")  
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","y","SciTE.exe")
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithList","MRUList","ya")
	 result = objReg.CreateKey(HKEY_CURRENT_USER, FILE_EXT_PATH  & fileExt & "\OpenWithProgIDs")
   result = objReg.setStringValue(HKEY_CURRENT_USER, FILE_EXT_PATH & fileExt & "\OpenWithProgIDs","Applications\Scite.exe","")
  