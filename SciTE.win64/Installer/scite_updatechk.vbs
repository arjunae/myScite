' build@ cscript.exe /NOLOGO //D $(FilePath)

' Synchronous http get githubs readme.md
set  http = CreateObject("WinHttp.WinHttpRequest.5.1")
http.SetTimeouts 30000,30000,30000,30000
http.Open "GET", "https://sourceforge.net/p/scite-webdev/code/ci/master/tree/readme.md?format=raw", false
http.Send

' Handle all lines / by LF
arr_lines=Split(http.responseText,chr(10))
'WScript.echo (ubound (arr_lines))
for each str in arr_lines
WScript.echo(str)
next


