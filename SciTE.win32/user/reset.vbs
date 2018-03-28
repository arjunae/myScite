 Const HKEY_CLASSES_ROOT	= &H80000000
 Const HKEY_CURRENT_USER	= &H80000001
 Const HKEY_LOCAL_MACHINE	= &H80000002
 Const HKEY_USERS								= &H80000003
 Const FILE_EXT_PATH	= "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\"
 Const FILE_EXT_PATH_CLS	= "Software\Classes\"

 Dim objReg ' Initialize WMI service and connect to the class StdRegProv
 strComputer = "." ' Computer name to be connected - '.' refers to the local machine
 Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

 Dim iKeyExist
 Dim strComputer
 Dim autofileExt

   autofileExt="cfg" & "_auto_file"   
   ' "yodaForce" Mode - start Clean with every handler resetted
		result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS  & fileExt)
    result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS  & autofileExt& "\shell\open\command")
		result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS  & autofileExt& "\shell\open")
		result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS  & autofileExt& "\shell")
		result = objReg.DeleteKey(HKEY_CURRENT_USER, FILE_EXT_PATH_CLS  & autofileExt)
		
		

		WScript.Echo(result & " " & Err.number & HKEY_CURRENT_USER & FILE_EXT_PATH_CLS  & autofileExt & "\shell\open\command")
		'Computer\HKEY_CURRENT_USER\Software\Classes\cfg_auto_file
