'build@  cscript.exe //x /NOLOGO $(FilePath)
'-------------------------------------------------
' jqapi.com Parser - ( http://jqapi.com)
' Status: 20151106 - Support parsing  local Source
' http://jqapi.com/#download
' Status: 20151122 - Fixup Sync
' Marcedo[at]gmx[dot]net
'
  Dim iSyncCnt 'As Integer
  Dim obrowser 'As InternetExplorer
  Dim result 'As Variant
  
 'Sub vba_jqapi()
  Set obrowser = CreateObject("InternetExplorer.Application")

  ' ---- MsHtml objekt:
  '  http://msdn.microsoft.com/en-us/library/aa741322%28v=vs.85%29.aspx
  ' ---- Properties
  '  http://msdn.microsoft.com/en-us/library/aa752084%28v=vs.85%29.aspx#properties
  '---- Methods
  ' http://msdn.microsoft.com/en-us/library/aa752084%28v=vs.85%29.aspx#methods

  obrowser.Visible = True
  obrowser.Silent = True
	
  'download link: http://jqapi.com/#download

  QualifiedName= wscript.ScriptFullName
  QualifiedPath= Replace(QualifiedName,wscript.ScriptName,"")
  MsgBox ( "Please allow access to: " & "file://" & QualifiedPath & "jqapi\index.html")
		
  obrowser.Navigate2 ("file://" & QualifiedPath & "jqapi\index.html")
  
  wscript.Sleep(8000)
  obrowser.StatusBar = True
  result = fSyncBrowser
  result = fParseResult(obrowser)

  obrowser.Quit
  Set obrowser = Nothing
 ' MsgBox ("Cooked " & result & " Entries.´:) Fini !")

'End Sub

' ---------------------------------------------------------------------

Function fParseResult(obrowser)

 Dim fso 'As Scripting.FileSystemObject
 Dim ofile_api, ofile_keywords, ofile_links 'As Scripting.File
 Dim htmldoc 'As MSHTML.HTMLDocument
 Dim sidebar, otblMainCats 'As MSHTML.HTMLDivElement

 '---------- prepare textfiles
 Set fso = CreateObject("Scripting.FileSystemObject")
 Set ofile_api = fso.CreateTextFile("jQuery.api.raw")
 Set ofile_keywords = fso.CreateTextFile("jQuery.keywords.raw")
 Set ofile_links = fso.CreateTextFile("jQuery.keywords.links")

 Set htmldoc = obrowser.Document
 result = fSyncBrowser

' htmldoc.onreadystatechange = fSyncBrowser

 '----------- Check for Sidebar
 If IsObject(htmldoc.getElementById("sidebar-content")) Then
   Set sidebar = htmldoc.getElementById("sidebar-content")
   Do: Loop Until Len(sidebar.outerText) > 100
 Else
   Exit Function
 End If

 '----------- grab  left sidbar
 Set otblMainCats = sidebar.getElementsByClassName("top-cat")
 'excel_row = 2

  Dim oApiEntry 'As MSHTML.HTMLGenericElement
  Dim oMainCat 'As MSHTML.HTMLDivElement
  Dim active_cat, api_name_short, api_link, api_params, api_descr 'As String
    
 '----------- click entries
 For Each oMainCat In otblMainCats
  
  oMainCat.Children(0).Click
  result = fSyncBrowser

  'Debug.Print "opening Category: " & oMainCat.Children(0).innerText
  active_category = oMainCat.Children(0).innerText
  Set oList = oMainCat.getElementsByClassName("entry")

  For Each oListEntry In oList
    'Debug.Print oListEntry.innerText
    oListEntry.Click
    result = fSyncBrowser

  '---------- Fetch api data from Main window
    Set oApiEntry = htmldoc.getElementById("signatures-nav").getElementsByTagName("span")
    
    For Each oApiParams In oApiEntry
    result = fSyncBrowser
    
  '----------- grab  left sidbar
    Set otblMainCats = sidebar.getElementsByClassName("top-cat")
    'excel_row = 2
                  
      '------------------  Output...
        api_active_cat = active_category
        api_link = htmldoc.Location.href
        api_params = oApiParams.innerText

      ' ------- Handle Operator Style Selectors
      ' --- aka "Attribute Contains Word Selector [name~="value"]"
        If InStr(1, api_name_short, "Selector [") Or InStr(1, api_name_short, "Selector (") Then
          api_name_short = "" '----- skip for keywords.properties
          api_params = "..() " & api_params
        End If
  
      '------- Special Handling for Selectors
        If InStr(1, api_name_short, ":") Then
        '---- remove suffix
          clean_pos = InStr(1, api_name_short, "Selector")
          api_name_short = Left(api_name_short, clean_pos - 1) & " "
  
        '-------- Insert a bogus (no_param)
          If Not InStr(1, api_name_short, ")") Then
           first_space = InStr(1, api_params, " ")
           api_params = Left(api_params, first_space) & "(no_param) " & Right(api_params, Len(api_params) - first_space)
          End If
        End If
        
        api_descr = obrowser.Document.getElementById("entry-header").all(1).innerText
        
      '-------- Insert multiline break to Descriptions > 79 chars
        If Len(api_descr) > 79 Then
          spacepos = 0: dotpos = 0: commapps = 0
          spacepos = InStr(65, api_descr, " ") ' search for a good place,try to be a bit clever.
          dotpos = InStr(40, api_descr, ".")
          commapos = InStr(40, api_descr, ",")
  
      '------ try to wrap on "." and ","
        If spacepos > 1 Then wrappos = spacepos
        If dotpos > 1 And dotpos < 70 Then wrappos = dotpos
        If commapos > 1 And commapos < 70 Then wrappos = commapos
            api_descr_multiline = Left(api_descr, wrappos) & "\t\n " 'Linebreak works only as documented if using \t beforehand...
            api_descr = api_descr_multiline & Right(api_descr, Len(api_descr) - wrappos)
        End If
  
      '------- fix obious dupes and write to files
        If 0 = InStr(1, all_keywords, api_name_short) Then
          all_keywords = all_keywords & api_name_short & " "
          ofile_keywords.Write (api_name_short) & " "
          ofile_links.Write (api_name_short) & ";" & api_link & vbCrLf
        End If
          
        If 0 = InStr(1, all_api_params, api_params) Then
          all_api_params = all_api_params & api_params & " "
          ofile_api.WriteLine (api_params + " " + api_descr + " ->" & api_active_cat)
        End If
  
        'works in excel too....
        'Cells(excel_row, 1).Value = "->" & api_active_cat
        'Cells(excel_row, 2).Value = api_params
        'Cells(excel_row, 3).Value = api_descr
        'rownr = rownr + 1
        '----------------------
      Next

    Next
  'Debug.Print "Closing category: " & oCat.Children(0).innerText
  oMainCat.Children(0).Click ' Kategorie wieder schliessen
  Next

  ofile_api.Close
  ofile_keywords.Close
  ofile_links.Close
  
End Function

Private Function fSyncIE()
  'do stuff and ..
  Call fSyncBrowser

End Function

Private Function fSyncBrowser()
  Do
    If obrowser.ReadyState = 4 And obrowser.Busy = False And obrowser.Document.ReadyState = "complete" Then
    fSyncBrowser = True
    obrowser.StatusText = "Syncing ... " & iSyncCnt
    Exit Function
    Else
     iSyncCnt = iSyncCnt + 1
    End If
  Loop
End Function

