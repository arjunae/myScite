' (not so Bitschyy) function parser '
'  alpha 07 - does not depend on ie. / doesnt crash.
'  alpha 0.8 - move retType behind params / search reference.txt for function descriptions
' inFile -> File generated with simple.phpm containing Hrfefs to parse
' outfile -> File containing the WebScraüed function definitions
' Marcedo@habMalNeFrage.de

inFile = "php_core_ref.txt"

' Unicode and Vbs arent "real friends (tm)".... 
const ForReading=1
const ForWriting=2
const ForAppending=8
const TristateUseDefault=-2 
const TristateTrue=-1 'Unicode
const TristateFalse=0 'ASCII
dim ofile_ref, ofile_docs
dim arrDescr()

' Stonehenge was great science back 3000 Years ago.
' its still a wonder how peops wre able to work like that.....
if instr(1,wscript.fullName,"cscript") then bConsole=true
set fso = CreateObject("Scripting.FileSystemObject")
set oXML = CreateObject("MSXML2.ServerXMLHTTP") ' more advanced then XMLHTTP 
set ohtmlFile = CreateObject("HTMLFILE") ' funny Task : find an object Reference on MSDN ? '
' also htmlfile_FullWindowEmbed and mhtmlfile
'	.toString
'	.nodeName
'	.nodeType
' .className
'	.parentNode.nodeName
'	.childNodes(0).nodeName
'	.firstChild.nodeName
'	.nextSibling.nodeName
'	.previousSibling.nodeName
	
wscript.quit(main)

function main()
dim arg0

	if not bConsole then exit function

	iCntArgs= WScript.Arguments.count 
	if iCntArgs > 0 then
	 arg0 = WScript.Arguments.Item(0)
	else
		'wscript.echo "no filename given"
		arg0=inFile
	end if

	arg0=replace(arg0,".txt","" )
	Set ofile_dir = fso.OpenTextFile(arg0 & ".txt", ForReading,TristateTrue)
	Set ofile_ref = fso.OpenTextFile(arg0 & ".func.txt", ForWriting,TristateTrue)
	getDescrFromFile()
	
	while not ofile_dir.AtEndOfStream
		ln= trim(ofile_dir.ReadLine())
		arr_ln=split(ln,";")
		if InStr(ln,".php") then getfnLink(arr_ln(0))
	wend

	ofile_dir.close()
	ofile_ref.close()
	ofile_docs.close()
end function


function getDescrFromFile()

	set ofile_docs = fso.OpenTextFile("reference.txt", ForReading,TristateTrue)
	redim preserve arrDescr(0)	
		
	while not ofile_docs.AtEndOfStream
		ln= trim(ofile_docs.ReadLine())
		arrMax=UBound(arrDescr)
		redim preserve arrDescr(arrMax+2)	
		
		paramStartPos=instr(ln,"(") -1
		funcName=mid(ln,1,paramStartPos)
		arrDescr(arrMax+1) =funcName
		
		paramEndPos=instr(ln,")") +2
		descr=mid(ln,paramEndPos,len(ln)-paramStartPos +1 )
		arrDescr(arrMax+2) =descr
		
	  ''wscript.echo( paramStartPos &" " & paramEndPos & " " & funcName & "|" & descr)
	wend
	
end function


function getfnLink(url)
	''https://stackoverflow.com/questions/3836130/vbs-microsoft-xmlhttp-status
	dim alias,strMethodName

	oXML.open "GET" , url ,false	'synchronous'	
	oXML.send()	

	on error resume next
	bla=oXML.status
	wscript.echo err.description
	
	if err.number >0 then wscript.echo(222)
	do 	
		i=i+1 :	if i> 10 then exit function 'todo timeout?
		wscript.sleep(250)
	loop until oXML.status=200

	'Strange way to assign them...
	ohtmlFile.Write oXML.responseText 
	ohtmlFile.Close

	' HTMLFILE has no getElementsByClassName - so iterate through
	Set oDiv = ohtmlFile.getElementById("layout")
	alias=false
	
	for each oItem in oDiv.all '-- Parse Description Content
	
	
	' Functions Name
	if oItem.ClassName ="refname" then 
			strMethodName=oItem.innerText
	end if
		
	if oItem.ClassName ="refsect1 description" then 
			''wscript.echo(url & vbcrlf & oitem.innerText)

			' For Function Aliases, writ their name and the name of the original		
			if  instr(oItem.innerText,"alias of")>0 then alias=true
			if  instr(oItem.innerText,"deprecated")>0 then alias=true

			' -- remove fat
			strraw=replace(oItem.innerText,"Description", "")
			strraw=replace(strRaw,vbLF &"Procedural style", "")
			''wscript.echo(strRaw)
				
			' -- split parameters to an array
				x=split(strRaw,vbLf)					
				strFunc = replace(x(1),vbcr,"")
				
			' move returnVal behind the functionParams	
				firstSpace=instr(strFunc," ")
				if firstSpace>0 then
					returnType = mid(strFunc, 1, firstSpace)
					strFunc = Replace(strFunc, returnType,"")
				end if
				
			' -- Function Description - Some Functions dont seem to have one
				if UBound(x)=2 then 
					strDescr = replace(x(2),vbcr,"")
				else 
					noDescr=true		
				end if		
		end if
		
	next
	
	if noDescr then 	' try to get the function description from reference.txt	
		for i =1 to UBound(arrDescr)-1 step 2
		'	wscript.echo(arrDescr(i) & " " & strMethodName)
			if arrDescr(i) = strMethodName then  strDescr=arrDescr(i+1) : DescrFound="[reference.txt]->"
		next
	end if
	
	if alias=true then  strFunc=strMethodName & "(->) " & strFunc
	if bConsole then wscript.echo  strFunc & ":" & returnType & DescrFound & strDescr
	ofile_ref.WriteLine (strFunc & ":" & returnType & " | " & replace(strDescr,vbLF,"") )
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
				strRes=strRes&subMatch & "|"
			next
		next
		regexp=split(strRes,"|")
	end if	
	
end function
