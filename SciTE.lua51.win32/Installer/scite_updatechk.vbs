' build@ cscript.exe /NOLOGO //D $(FilePath)

Dim versions()

' Synchronous http get githubs readme.md
set  http = CreateObject("WinHttp.WinHttpRequest.5.1")
http.SetTimeouts 30000,30000,30000,30000
http.Open "GET", "https://sourceforge.net/p/scite-webdev/code/ci/master/tree/readme.md?format=raw", false
http.Send

iterateFile(http.responseText)
WScript.echo(ubound(versions))


function iterateFile(content)
' Handle all lines / by LF
	arr_lines=Split(content,chr(10))
	'WScript.echo (ubound (arr_lines))
	redim  versions(1)
	for each str in arr_lines
	'str="#Version: 2017_12_09, #6ae5f442, 180, Artie, win32"
		collectVersions(str)
	next
end function

private function collectVersions(str)
	if Left(str,9) ="#Version:" then
		redim  preserve versions(ubound(versions)+1)
		versions(1) = mid(str,9,10)
	end if
end function

'  scilexer.dll
'  'date , CRC32 Hash , VersionNumber , VersionString , Platform
'"#Version: 2017_12_09, #6ae5f442, 180, Artie, win32" 
'"#Version: 2017_12_09, #657db4c7, 180, Artie, win64"
'"#Version: 2017_12_09, #f5da9245, 190, MartyMcFly_lua51, win32"
'"#Version: 2018_07_13, #6dc538c0, 190, MartyMcFly_lua53, win64"
'"#Version: 2018_07_13, dc789340, 190, MartyMcFly_lua53, win32"
'#EndVersions


