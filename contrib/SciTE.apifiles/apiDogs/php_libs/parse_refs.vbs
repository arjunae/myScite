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

set fso = CreateObject("Scripting.FileSystemObject")
set http = CreateObject("WinHttp.WinHttpRequest.5.1")


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
	exit function
	wend

	ofile_dir.close()
	ofile_ref.close()
end function

function getfnLink(url)

''https://officetricks.com/vbscript-extract-data-web-scrape-parse-html/
	set oXML = CreateObject("MSXML2.XMLHTTP")
	set ohtmlFile = CreateObject("HTMLFILE")
	wscript.echo(url)
	oXML.open "GET" , url ,async	
	oXML.send()
	
    'Get Web Data to HTML file Object
		do  
			wscript.sleep(50)
		loop until oXML.Status=200 
		
    ohtmlFile.Write oXML.responseText
   ohtmlFile.Close
' vbscript WTF - HTMLFILE Objext SUCKS
		Set oTable = ohtmlFile.getElementById("layout")
		'wscript.echo(oTable.innerText)
		for each bla in oTable.all
		if bla.ClassName ="methodname" then wscript.echo(bla.innerText)
		if bla.ClassName ="refsect1 description" then wscript.echo(bla.innerText)
		if bla.ClassName ="refsect1 returnvalues" then wscript.echo(bla.innerText)		
	''	wscript.echo(bla.innerText)

next

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

