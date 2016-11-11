/* build@ cscript.exe //E:jscript /NOLOGO //X $(FilePath) '
 *  .... Doc Comments seem to be okay.
 */
 	
// Check syntax Highlitening and multiline calltips.
		var MyVeryLongVar = MyVeryLongVar + 20 - 0xA + 2;
		var str = "asdf".replace (/ ^['"]/, "");

// Underscore Library
	var fs = new ActiveXObject("Scripting.FileSystemObject");
	result=eval(fs.OpenTextFile("./data/underscore.js").ReadAll());
	if ( typeof(_)=="function") {
		WScript.stdout.write("- Underscore v" + _.VERSION + " with jScript :)- \n");
	}
	
// Random Value
	var arr=[_.random(12),_.random(12)]
	//var sz=_.size(arr);
	WScript.echo(":: _.random(12) :: "+ arr);


// Ajax
	WScript.echo("\n-:: jScript AJAX Test ::-")
	http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	http.Open("GET", "https://raw.githubusercontent.com/arjunae/myScite/master/.gitattributes", false);
	http.Send;
	WScript.Echo("http.StatusText:" + http.StatusText + "\nhttp.responseText:\n " + http.responseText);

