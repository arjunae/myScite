Dim oFso 'As Scripting.FileSystemObject

'Sub vba_msdn_write_api()

Dim oFile_links 'As TextStream
Dim iPosArr 'As Integer
Dim ArrEntry()
dim sFileName

  Set oFso = CreateObject("scripting.FilesystemObject")
  Set oFile_links = oFso.OpenTextFile("msdn.js.api.raw", 1, True) ' forRead, CreateFlag
  sFileName ="javascript.api.raw"
  
  ' ---- Start Parsing, fill oEntries
  On Error Resume Next

  Set oEntries = CreateObject("System.Collections.ArrayList")
  While Not oFile_links.AtEndOfStream
       
    ' ---- Format: Each Line contains ";" linked Entries, second Entry is EntryCount, EOL is  CrLF
    ' ---- valid Entries start with an numeric Identifier between 1-3, describing its Contents type.
    
    sChar = oFile_links.Read(1)
    If Not IsNumeric(sChar) Then
      oFile_links.SkipLine
    Else
      Set oEntry = CreateObject("System.Collections.SortedList")
      ReDim ArrEntry(2)
      iPosArr = 0
    Do
      ' ---- Entry separator is ";" Line Prefixed  "#" is a comment
        strPuzzle = strPuzzle & sChar
        If sChar = ";" Then
        strPuzzle = Replace(strPuzzle, ";", "")
        strPuzzle = Trim(strPuzzle)
      
      ' ---- Each line has a Lenght Entry describing its number of containing Entries
        If iPosArr = 2 Then
          iLineLen = strPuzzle
          ReDim Preserve ArrEntry(iLineLen)
        Else
          If Err.Number > 0 Then MsgBox "Expected EOL, got ;": Stop
          Err.Clear
        End If
        ArrEntry(iPosArr) = strPuzzle
        iPosArr = iPosArr + 1
        strPuzzle = ""
      End If
        
      sChar = oFile_links.Read(1)
      Loop Until oFile_links.AtEndOfLine
  
      strPuzzle = Replace(strPuzzle, ";", "")
      ArrEntry(8) = Trim(strPuzzle) & sChar
  
      ' Define a Key/Value Collection and store it
      oEntry.Add "LinkType", ArrEntry(0)
      oEntry.Add "LinkId", ArrEntry(1)
      oEntry.Add "LinkLength", ArrEntry(2)
      oEntry.Add "sParentObject", ArrEntry(3)
      oEntry.Add "LinkName", Replace(ArrEntry(4), "()", "")
      oEntry.Add "LinkParams", ArrEntry(5)
      oEntry.Add "LinkDescr", Replace(ArrEntry(6), "!", "(**)")
      oEntry.Add "LinkHref", ArrEntry(7)
      oEntry.Add "oApiSyntax", replace(ArrEntry(8),"),",");")
      oEntries.Add oEntry
      'Debug.Print oEntry("LinkName")
      
      strPuzzle = ""
     End If
  Wend

' now... finish the puzzle

result = Write_API(oFile_links, oEntries)
result = Write_Keywords(oFile_links, oEntries)

'oFile_links.Close

'End Sub

Private Function Write_API(oFileLinks, oEntries)

  Dim ofile_Api 'As Scripting.TextStream
  Set ofile_Api = oFso.CreateTextFile( sFilename )
  
  For Each oEntry In oEntries
  

' --- Store Objects Name (LinkType==1) (is root class like eg "Object" or "Array")
    If oEntry("LinkType") = 1 Then
      sParentObject = oEntry("LinkName")
      sApiPrefix = ""
    End If
    
' --- Add a Dot if none found and objects name isnt already in Apis Name.
    If oEntry("LinkType") > 1 Then
      If 0 = InStr(1, oEntry("LinkName"), ".") Then sApiPrefix = sParentObject & "."
      If Left(oEntry("LinkName"), Len(sParentObject)) = sParentObject Then sApiPrefix = ""
    End If

	api_descr =oEntry("LinkDescr")
	
      '-------- Insert multiline break to Descriptions > 75 chars
        If Len(api_descr) > 75 Then
          spacepos = 0: dotpos = 0: 
          spacepos = InStr(58, api_descr, " ") ' search for a good place,try to be a bit clever.
          dotpos = InStr(40, api_descr, ".")
		
		'------ try to wrap on "." and " "
			If spacepos > 57 And spacepos < Len(api_descr) Then wrappos = spacepos
			If dotpos > 40 And dotpos < Len(api_descr)-5	Then wrappos = dotpos

            api_descr_multiline = Left(api_descr, wrappos) & "\t\n " 'Linebreak works only as documented if using \t beforehand...
            api_descr = api_descr_multiline & Right(api_descr, Len(api_descr) - wrappos)
        End If
	
	'vba Debug.Print sApiPrefix & oEntry("LinkName") & oEntry("LinkParams") & " " & oEntry("LinkDescr") & sParentObject & "\t\n" & oEntry("oApiSyntax")

    ofile_Api.Write  sApiPrefix & oEntry("LinkName") & oEntry("LinkParams") & " " & api_descr & "\t\n" & oEntry("oApiSyntax") & vbCrLf
 
  ' --- As we have two outputs, check if we already wrote it.
    sDupeCheck =  sApiPrefix & oEntry("LinkName")
 
  ' ---  Now, once again, but lets only store Object functions with a trailing dot
  ' --- (so ArrayBuffer.slice will get .slice )

    sFnPrefix = "."
   ' If oEntry("LinkType") = 1 Then sFnPrefix = ""
    If Left(oEntry("LinkName"), Len(sParentObject)) = sParentObject Then sFnPrefix = ""
    
   If Not (sDupeCheck = sFnPrefix & oEntry("LinkName")) Then
      ' vba Debug.Print sFnPrefix & oEntry("LinkName") & oEntry("LinkParams") & " " & oEntry("LinkDescr") & " -->" & sParentObject & "\t\n" & " " & oEntry("oApiSyntax")
      ' ofile_Api.Write sFnPrefix & oEntry("LinkName") & oEntry("LinkParams") & "\t\n " & "---- \t\n" & api_descr & "----\t\n" & oEntry("oApiSyntax") & vbCrLf
   End If
    
  Next
   
  ofile_Api.Close
End Function

Private Function Write_Keywords(oFileLinks, oEntries)

  Dim ofile_Api 'As Scripting.TextStream
  Dim sKeywords 'As String
  Set ofile_keywords = oFso.CreateTextFile("javascript.keywords.raw")
  
  For Each oEntry In oEntries
    
    If oEntry("LinkType") > 1 Then LinkPrefix = "."
    
    ' Dupe Check
    If Not InStr(sKeywords, oEntry("LinkName")) Then
      sKeywords = sKeywords & LinkPrefix & oEntry("LinkName") & " "
    End If
    
  Next

  ofile_keywords.Write sKeywords
  ofile_keywords.Close

End Function
