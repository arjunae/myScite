' very simple php apilinks fetcher
' -Fix: Unicode content
'
' InFile Format:
' String Description php core fns 
' CSVString Entry "book.array.php ;Arrays;"
' outFile
' CSVString http://php.net/manual/en/function.array-chunk.php;array_chunk
' http://php.net/manual/en/function.array-column.php;array_column

const ForReading=1
const ForWriting=2
const ForAppending=8
const TristateUseDefault=-2 
const TristateTrue=-1 'Unicode
const TristateFalse=0 'ASCII
dim bconcole

Set fso = CreateObject("Scripting.FileSystemObject")
Set ofile_dir = fso.OpenTextFile("php_core.txt",ForReading,TristateTrue)
Set ofile_ref = fso.OpenTextFile("php_core.ref.txt",ForWriting,TristateTrue)

wscript.quit(main)

function main()
	if instr(1,wscript.fullName,"cscript") then bConsole=true

		Description= ofile_dir.ReadLine()
	while not ofile_dir.AtEndOfStream
		ln= ofile_dir.ReadLine()
		arr_ln=split(ln,";")
		getfnLink(arr_ln(0))
	wend

	ofile_dir.close()
	ofile_ref.close()
end function

function getfnLink(strLnk)

strLnk=replace(strLnk,"book","ref")
url="http://php.net/manual/en/" & Trim(strLnk)
	
	set  http = CreateObject("WinHttp.WinHttpRequest.5.1")
	http.SetTimeouts 30000,30000,30000,30000
	
	http.Open "GET",url, false
	http.setRequestHeader "Content-Type", "text/html; charset=UTF-8"
	http.Send

	'http://winhttp.blogspot.com/ WorkAround UnicodeBug
	Set fileOut = FSO.CreateTextFile("utf8.txt", true, true)
	fileOut.Write http.responsebody
	fileOut.Close
	Set fileIn = fso.OpenTextFile("utf8.txt",ForReading,TristateTrue)
	content=fileIn.readAll()
	fileIn.Close()
	
	startPos=instr(content,"chunklist_reference")
	endPos=instr(content,"usernotes")
	if bConsole then	wscript.echo(url & " " & startPos & " " & endpos)
	getFunctionLinks Mid(content,startPos+25,endPos-startPos) , strLnk
	
end function

function getFunctionLinks(strhtml,lnk)

	Set myRegExp = New RegExp
	myRegExp.IgnoreCase = True
	myRegExp.Global = True
	myRegExp.IgnoreCase=True

	myRegExp.Pattern="([ .-a-zA-Z0-9]*).php....\w*"
	Set myMatches = myRegExp.Execute(strhtml)

	For Each myMatch in myMatches
		line=replace(myMatch.value,chr(34) & ">",";")
		line="http://php.net/manual/en/"&line
		if  not InStr(line, " ")>0 then  ofile_ref.WriteLine(line)
	Next

end function