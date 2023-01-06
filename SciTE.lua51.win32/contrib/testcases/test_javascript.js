/** build@ cscript.exe //E:jscript /NOLOGO //X $(FilePath) '
 * "electron-steampunk"
 *  	... Doc Comments seem to be okay.
 * 	@api CommentKeyword
*/
WScript.Echo( ScriptEngineMajorVersion() + "." +
              ScriptEngineMinorVersion() + "." +
              ScriptEngineBuildVersion());

// jscript 5.8 {f414c260-6ac0-11cf-b6d1-00aa00bbbb58}
// jscript Chacra 11 {16d51579-a30b-4c8b-a276-0ff4dc41e755}
	
// Check syntax Highlitening and multiline calltips.
var MyVar = MyVar + 20 - 0xA + 2;
var str = "asdf".replace (/ ^['"]/, "");

// Ajax
	WScript.echo("\n-:: jScript AJAX Test (reddit) ::-")
	http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	http.Open("GET", "https://www.reddit.com/r/aww.json", false);
	http.Send;
	WScript.Echo("http.responseText: " + http.responseText +"\n");