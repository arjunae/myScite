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
var MyVeryLongVar = MyVeryLongVar + 20 - 0xA + 2;
var str = "asdf".replace (/ ^['"]/, "");

// Underscore Library
	var fs = new ActiveXObject("Scripting.FileSystemObject");
	result = eval(fs.OpenTextFile("./data/underscore.js").ReadAll()); //  save_as_ansi...

	if ( typeof(_)=="function") {
		WScript.stdout.write("- Underscore v" + _.VERSION + " with .jScript Steampunk :)\n");
		result=eval(fs.OpenTextFile("./data/underscore.string.js").ReadAll()); //  save_as_ansi...
	 _.mixin(s.exports());  /// without s.include, s.contains, s.reverse and s.join.
	 
	 // Underscore.string Compare
		WScript.echo(":: _levenshtein:	"+ "compare~compaire=" +_.levenshtein("compare","compaire"));
		
	 // Random Value
		 var arr=[_.random(12),_.random(12)]
		 WScript.echo(":: _.random:	"+ arr +" ("+ _.size(arr)+")");

	 // JSON (./data/test_json.json)
		 var res=(fs.OpenTextFile("./data/test_json.json").ReadAll() +" "); //  save_as_ansi....
		 obj= eval(' ('  + res + ') ');
		 WScript.echo (":: test_json:	" + res);
		 WScript.echo(":: _.allKeys:	"+_.allKeys(obj))
		 WScript.echo(":: _.values:	"+_.values(obj))
}

// Ajax
	WScript.echo("\n-:: jScript AJAX Test (reddit) ::-")
	http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	http.Open("GET", "https://www.reddit.com/r/aww.json", false);
	http.Send;
	WScript.Echo("http.responseText: " + http.responseText +"\n");