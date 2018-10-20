'Veery Bitschyy Dirty function parser
'  /vbScript Hate/
' (...)
' todo:  calm down. rewrite and use a DOM Parser.

const ForReading=1
const ForWriting=2
const ForAppending=8
const TristateUseDefault=-2 
const TristateTrue=-1 'Unicode
const TristateFalse=0 'ASCII
dim bconsole
dim noComment

Set fso = CreateObject("Scripting.FileSystemObject")
set  http = CreateObject("WinHttp.WinHttpRequest.5.1")
http.SetTimeouts 30000,30000,30000,30000
	
Set ofile_dir = fso.OpenTextFile("php_core_ref.txt",ForReading,TristateTrue)
Set ofile_ref = fso.OpenTextFile("php_core.func.txt",ForWriting,TristateTrue)

wscript.quit(main)

function main()
	if instr(1,wscript.fullName,"cscript") then bConsole=true

	''Description= ofile_dir.ReadLine()
	while not ofile_dir.AtEndOfStream
		ln= trim(ofile_dir.ReadLine())
		arr_ln=split(ln,";")
		getfnLink(arr_ln(0))

	wend

	ofile_dir.close()
	ofile_ref.close()
end function

function getfnLink(url)

''wscript.echo(url)

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
	
	'prefilter fatty content 
	startPos=instr(content,"refsect1 description")
	endPos=instr(content,"</body")

	if bConsole then	wscript.echo(url & " " & startPos & " " & endpos)
		
end function

function regexp(strPattern,strContent)
' again very simple. 
' designed to return all submatches from all matches as an array 

	Set myRegExp = New RegExp
	myRegExp.IgnoreCase = True
	myRegExp.Global = True
	myRegExp.IgnoreCase=True

	myRegExp.Pattern=strPattern
	Set myMatches = myRegExp.Execute(strContent)
	
	''wscript.echo(myMatches.count)
	
	if myMatches.count>0 then
	''wscript.echo(myMatches.Item(0))
	''wscript.echo(myMatches.Item(0).submatches.count)
	''wscript.echo(myMatches.Item(0).submatches(0))

	for each myMatch in myMatches
		for each subMatch in myMatch.Submatches
		''wscript.echo(subMatch)
			strRes=strRes&subMatch&";"
		next
	next
	regexp=split(strRes,";")
	
	end if	
	
end function

