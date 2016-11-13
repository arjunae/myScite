/* build@ cscript.exe //E:jscript /NOLOGO //X $(FilePath) '
 *  .... Doc Comments seem to be okay.
 */
 	
// Check syntax Highlitening and multiline calltips.
		var MyVeryLongVar = MyVeryLongVar + 20 - 0xA + 2;
		var str = "asdf".replace (/ ^['"]/, "");

// Underscore Library
	var fs = new ActiveXObject("Scripting.FileSystemObject");
	result=eval(fs.OpenTextFile("./data/underscore.js").ReadAll()); //  save_as_ansi...
	if ( typeof(_)=="function") {
		WScript.stdout.write("- Underscore v" + _.VERSION + " with jScript Steampunk :)\n");
	}
	
// Random Value
	var arr=[_.random(12),_.random(12)]
	//var sz=_.size(arr);
	WScript.echo(":: _.random:	"+ arr);

// JSON (./data/test_json.json)
	var res=(fs.OpenTextFile("./data/test_json.json").ReadAll() +" "); //  save_as_ansi....
	obj= eval('('  + res + ')');
	WScript.echo (":: test_json:	" + res);
	WScript.echo(":: _.allKeys:	"+_.allKeys(obj))
	WScript.echo(":: _.values:	"+_.values(obj))

// Ajax
	WScript.echo("\n-:: jScript AJAX Test ::-")
	http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	http.Open("GET", "https://raw.githubusercontent.com/arjunae/myScite/master/.gitattributes", false);
	http.Send;
	WScript.Echo("http.StatusText:" + http.StatusText + "\nhttp.responseText:\n " + http.responseText);