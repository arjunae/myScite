
Set fso = CreateObject("Scripting.FileSystemObject")
Set ofile_dir = fso.OpenTextFile("php_pecl.txt",1)
Set ofile_ref = fso.OpenTextFile("php_pecl_ref.txt",8,true)

Description= ofile_dir.ReadLine()

while not ofile_dir.AtEndOfStream
ln= ofile_dir.ReadLine()
arr_ln=split(ln,";")
''wscript.echo(arr_ln(0))
getfnLink(arr_ln(0))
wend

ofile_dir.close()
ofile_ref.close()

function getfnLink(strLnk)
strLnk=replace(strLnk,"book","")
strLnk="ref"& strLnk
url="http://php.net/manual/en/" & Trim(strLnk)
	
	set  http = CreateObject("WinHttp.WinHttpRequest.5.1")
	http.SetTimeouts 30000,30000,30000,30000

	http.Open "GET", url, false
	http.Send

	on error resume next
	content=http.responseText
	startPos=instr(content,"chunklist_reference")
	endPos=instr(content,"usernotes")
	wscript.echo(url & " " & startPos & " " & endpos)
	
	getFunctionLinks Mid(content,startPos+25,endPos-startPos) , strLnk
end function

function getFunctionLinks(strhtml,lnk)
''wscript.echo(lnk)

Set myRegExp = New RegExp
myRegExp.IgnoreCase = True
myRegExp.Global = True
myRegExp.IgnoreCase=True

myRegExp.Pattern="([ .-a-zA-Z0-9]*).php....\w*"
Set myMatches = myRegExp.Execute(strhtml)
''Set ofile_ref = fso.OpenTextFile(Lnk&".txt",8,True)

For Each myMatch in myMatches

	line=replace(myMatch.value,chr(34) & ">",";")
	line="http://php.net/manual/en/"&line
	ofile_ref.WriteLine(line)
Next
	''ofile_ref.close()
end function