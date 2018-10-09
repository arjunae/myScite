'Synchronous
set  http = CreateObject("WinHttp.WinHttpRequest.5.1")
http.SetTimeouts 30000,30000,30000,30000
http.Open "GET", "https://sourceforge.net/p/scite-webdev/code/ci/master/tree/readme.md?format=raw", false
http.Send
'WScript.Echo "http.responseText: " + http.responseText +"\n"
Msgbox(http.responseText)