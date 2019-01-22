' build@ cscript.exe /NOLOGO //D $(FilePath)
'
' Download and parse scites readme.md, re/write stripped version info to tmp/scite_versions.txt 
'

wscript.quit(main)

function main()
dim	versions

on error resume next  
  ' Parse Commandline Arguments	
  iCntArgs= WScript.Arguments.count 
  if iCntArgs > 0 then 
	 url= WScript.Arguments.Item(0)
	 if err.number >0 then errHndlr()
  else
	 'url ="https://raw.githubusercontent.com/arjunae/myScite/master/readme.md"
    url= "https://raw.githubusercontent.com/arjunae/myScite/devel/readme.md"
    wscript.echo("Download URL: " & url)
  end if

  ' Synchronous http get githubs readme.md
  set  http = CreateObject("MSXML2.ServerXMLHTTP")
  http.SetTimeouts 30000,30000,30000,30000
  http.Open "GET", URL, false
  if err.number >0 then errHndlr()
  http.Send
  if err.number >0 then errHndlr()
  if http.Status <> 200 Then 
    errHndlr() 
    exit function
  end if
on error goto 0

  'write Version specific Lines to userstmpdir/scite_versions.txt
  Set wshShell = CreateObject( "WScript.Shell" )
  versions=iterateFile(http.responseText)
  writeTmpFile "\scite_versions.txt",versions
  if ubound(versions)=0 then errHndlr()
  WScript.echo("STATUS:OK")
end function


'-----------
' Helpers	
'-----------

'
' Write ArrayData to a given Filename in user/tmp 
'
function writeTmpFile(filename,arrContent)
'  wscript.echo(filepath&" "&arrContent(1))
  set oFso=CreateObject("Scripting.Filesystemobject")
  Set tmpDir = oFso.GetSpecialFolder(2)
  if not oFso.FolderExists(tmpDir & "\SciTE") then oFso.CreateFolder(tmpDir & "\SciTE")
  if oFso.FileExists(tmpDir & "\SciTE\" & fileName) then  oFso.DeleteFile(tmpDir& "\SciTE\" & fileName)
  set oFileOut = oFso.OpenTextFile(tmpDir & "\SciTE" & fileName,2, 1) ' forWrite, createFlag
  for each str in arrContent
	 if str<>"" then oFileOut.write(str)
  next
  oFileOut.close()
  set oFso=Nothing
end function

' 
' iterate through, split all lines by lf, filter in version specific content
' Version: 2017_12_09, #6ae5f442, 180, Artie, win32"	
'	
function iterateFile(content)
  dim versions
  redim versions(0)
  ' Handle all lines / by LF
	arr_lines=Split(content,chr(10))
	for each str in arr_lines
   	if Left(str,9) ="#Version:" then
		  redim  preserve versions(ubound(versions)+1)
		  versions(ubound(versions)) = trim(str)  & vbCrLf
		end if
		iterateFile=versions
	 next
end function

function errHndlr()
  'wscript.echo( VbCRLF & "-- " & err.Number & ", " & err.Description & VbCRLF & "-- " &  err.source)
  Wscript.echo("STATUS:Error Creating versions.txt failed")
  wscript.quit
end function

'  scilexer.dll
' Date , CRC32 Hash , VersionNumber , VersionString , Platform
'#Version: 2018_10_09, c0d5e2e7, mySciTE_190_01_MartyMcFly_lua53_win32,0
'#Version: 2018_10_09, 6dc538c0, mySciTE_190_01_MartyMcFly_lua53_win64,0
'#Version: 2018_10_09, f5da9245, mySciTE_190_01_MartyMcFly_lua51_win32,0
'#Version: 2018_07_13, dc789340, mySciTE_190_MartyMcFly_lua53_win32,1
'#Version: 2018_07_13, 68970227, mySciTE_190_MartyMcFly_lua53_win64,1
'#Version: 2017_12_09, 6ae5f442, mySciTE_180_Artie_win32,1
'#Version: 2017_12_09, 657db4c7, mySciTE_180_Artie_win64,1