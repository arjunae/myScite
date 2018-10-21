' Veery Bitschyy function parser
'  /vbScript Hate/
' (...)
' todo:  calm down. rewrite and use a DOM Parser.
' (%!&UUC!!K!) 
' hrmpf -ok. seems usable..

const ForReading=1
const ForWriting=2
const ForAppending=8
const TristateUseDefault=-2 
const TristateTrue=-1 'Unicode
const TristateFalse=0 'ASCII
dim bconsole

set fso = CreateObject("Scripting.FileSystemObject")
Set ofile_dir = fso.OpenTextFile("php_core_ref.txt",ForReading,TristateTrue)
Set ofile_ref = fso.OpenTextFile("php_core.func.txt",ForWriting,TristateTrue)
set oXML = CreateObject("MSXML2.ServerXMLHTTP") ' more advanced then XMLHTTP 
set ohtmlFile = CreateObject("HTMLFILE") 

wscript.quit(main)

function main()
	if instr(1,wscript.fullName,"cscript") then bConsole=true

	while not ofile_dir.AtEndOfStream
		ln= trim(ofile_dir.ReadLine())
		arr_ln=split(ln,";")
		getfnLink(arr_ln(0))
	wend

	ofile_dir.close()
	ofile_ref.close()
end function

function getfnLink(url)
	''https://stackoverflow.com/questions/3836130/vbs-microsoft-xmlhttp-status
	dim alias
	dim strMethodName

	oXML.open "GET" , url ,false	'synchronous'
	oXML.send()	
	do  
		wscript.sleep(250) 
		'todo timeout?
	loop until oXML.status=200

	'Strange way to assign them...
	ohtmlFile.Write oXML.responseText 
	ohtmlFile.Close
	
	' HTMLFILE has no getElementsByClassName - so iterate through
	Set oDiv = ohtmlFile.getElementById("layout")
	alias=false
	
	for each oItem in oDiv.all				
		'-- Parse Description Content
		if oItem.ClassName ="refsect1 description" then 
			'wscript.echo(oitem.innerText)
			if  instr(oItem.innerText,"alias of")>0 then alias=true
			' -- parameters
				strraw=replace(oItem.innerText,"Description", "")
				''wscript.echo(strRaw)
				x=split(oItem.innerText,vbLf)			
				strFunc = replace(x(1),vbcr,"")
			' -- Function Description - Some Functions dont seem to have one
				if UBound(x)=2 then strDescr = replace(x(2),vbcr,"")
		end if	
	
	' For Function Aliases, writ their name and the name of the original		
		if oItem.ClassName ="refname" then 
			strMethodName=oItem.innerText		
		end if
	next
		
	if alias=true then  strFunc=strMethodName & "(->) " & strFunc
	if bConsole then wscript.echo strFunc & " " & strDescr	
	ofile_ref.WriteLine (strFunc & " " &  replace(strDescr,vbLF,"") )
	''if oItem.ClassName ="refsect1 returnvalues" then wscript.echo(oItem.innerText)		
		
end function


' a Leftover - just here in case we need that sometimes
function regexp(strPattern,strContent)
' again very simple. No Multilines
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
