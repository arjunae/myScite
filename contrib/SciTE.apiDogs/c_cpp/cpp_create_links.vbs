'build@  cscript.exe //x /NOLOGO $(FilePath)
'-------------------------------------------------
' cplusplus.com Parser - ( http://cplusplus.com)
' Status: 20160221 - Fixup Sync, add timeout / retry /fail
' Status: 20160222 - Add simple File logging
' Status: 20160312 - Utilize DocumentComplete Event.
' Marcedo[at]habmalnefrage[dot]net
'
const MAX_TRIES = 3

' VBS doesnt support types as VBA, so comment them out
  Dim iSyncCnt 'As Integer
  Dim obrowser 'As InternetExplorer
  Dim DocumentComplete

  Dim result 'As Variant
  Dim ofile_log 'AS Scripting.File

 Phase1()

'------------------------------------------------------

sub phase1()

  Set fso = CreateObject("Scripting.FileSystemObject")
  Set ofile_log = fso.CreateTextFile("cpp.keywords.log")
  Call reset_ie

  ' Its a use case that parsin IEs output can be blocked by client, network or server side hangs.
  ' implemented those retries and following check to deal with slow or lossy content.
  ' Since this has been done, stability problems were gone completely.

  For i = 1 To MAX_TRIES
    debug_log ("opening WebSource")
    obrowser.Navigate2 ("http://www.cplusplus.com/reference/clibrary/")
    result = fSyncBrowser
    If result = 0 Then Exit For Else reset_ie
  Next

 '----------- Now, doublecheck for site beein completely loaded.
  If IsObject(obrowser.Document.getElementById("I_footer")) Then
    Set footer_check = obrowser.Document.getElementById("I_footer")
    Do: Loop Until (footer_check.Children(1)) = "http://www.cplusplus.com/privacy.do"
  Else
    debug_log ("--- Problems while loading Site- STOP")
    obrowser.Quit
    ofile_log.Close
    Set ofile_log = Nothing
    Set obrowser = Nothing
  Exit sub
  End If

  result = fParseResult(obrowser)
  MsgBox("Your meal is ready")

  obrowser.Quit
  Set obrowser = Nothing
  ofile_log.Close
End sub

'------------------------------------------------------------

Function reset_ie()
' This one resets IE in case we have occuring a timeout.
' called automatically in case of a request timeout.

' In case of a client side browser fail, just call reset_ie manual from debug window.
' we could automate that too, but this case happens nearly never, so...

  ' ---- MsHtml objekt:
  '  http://msdn.microsoft.com/en-us/library/aa741322%28v=vs.85%29.aspx
  ' ---- Properties
  '  http://msdn.microsoft.com/en-us/library/aa752084%28v=vs.85%29.aspx#properties
  '---- Methods
  ' http://msdn.microsoft.com/en-us/library/aa752084%28v=vs.85%29.aspx#methods

  If IsObject(obrowser) Then
    debug_log ("Timeout - Resetting IE")
    obrowser.Quit
  End If

  Set obrowser = wscript.CreateObject("InternetExplorer.Application","obrowser_") 'VBS
  'Set obrowser = CreateObject("InternetExplorer.Application") 'VBA
  obrowser.Visible = True
  obrowser.Silent = True
  obrowser.StatusBar = True

  Do: Loop Until obrowser.ReadyState = 0 ' wait for Object to be initialized
End Function

' ---------------------------------------------------------------------

Sub obrowser_DocumentComplete(byref obj, byref URL) 'VBS
'-------------------
' Catch IE Controls DocumentComplete Event.
' fires on any (even javascript)  loaded URL, so only react on LocationBars URL
' Vbs Events work diffrent then vba ones.
' eg do:  htmldoc.onreadystatechange = fSyncfunc
' or do: obrowser_event(byref...)
'------------------

  If  obrowser.locationURL = URL then
    'msgbox("URL:" & URL)
    documentComplete= True
    wscript.Sleep (50)
  End if
  
End sub

' ---------------------------------------------------------------------

Function debug_log(log_str)
' ---- very simple logger, requires ofile_log to be global and writeable

  'debug.print log_str
  ofile_log.WriteLine log_str

End Function

' ---------------------------------------------------------------------

Function fParseResult(obrowser)
'---- takes a browser object, parses its contents

 Dim fso 'As Scripting.FileSystemObject
 Dim oFile_links 'As Scripting.File
 Dim htmldoc 'As MSHTML.HTMLDocument
 Dim olistEntry 'As MSHTML.HTMLGenericElement
 Dim oSidebar 'As Object

 Set htmldoc = obrowser.Document

 '---- Prepare textfiles
 Set fso = CreateObject("Scripting.FileSystemObject")
 Set oFile_links = fso.CreateTextFile("cpp.keywords.links.raw")

'  ---- First Step :  iterate the sidebar and store links

  Set oApiList = CreateObject("System.Collections.arrayList")

  Set oSidebar = obrowser.Document.getElementById("reference_box").getElementsByTagName("ul")
  Set olistEntries = CreateObject("System.Collections.arrayList")

  For Each Category In oSidebar
    Set Links = oSidebar(0).getElementsByTagName("A")
    
    For Each link In Links
        debug_log (link.uniqueNumber & "," & link.href)
        If InStr(1, checkdupe, link.href) = 0 Then
          checkdupe = checkdupe & link.href
          If link.outerText <> "C library:" Then olistEntries.Add link.href
        Else
          debug_log ("ign Dupe:" & link.href)
        End If
    Next
  Next

  '---- Next we will open the links in Sidebar
  Set oApiEntries = CreateObject("System.Collections.arrayList")

  For Each link In olistEntries

    For i = 1 To MAX_TRIES
        debug_log ("click -> " & link)
        obrowser.Navigate2 link
        result = fSyncBrowser
        If result = 0 Then Exit For Else reset_ie
    Next

    '---- The Sidebar has two Info Boxes. TopBox contains the MainNav, BottomBox contains detail information
     Set sidebar = obrowser.Document.getElementById("I_nav").getElementsByClassName("C_BoxSort")

    If sidebar.Length > 1 Then
    Set sidebar_bottom = sidebar(1)
        For Each myApiEntry In sidebar_bottom.getElementsByTagName("A")

          Set oApiEntry = CreateObject("System.collections.sortedList")

          '---- Add new api metadata here:

          If InStr(1, myApiEntry.outerText, "<") = 0 Then

            oApiEntry.Add "api_name", myApiEntry.outerText
            oApiEntry.Add "api_href", myApiEntry.href
            oApiEntry.Add "api_compat", myApiEntry.ParentNode.className

            '---- Join the apis type, by referin the href to main window
            Set mainwintags = obrowser.Document.getElementById("I_content").getElementsByTagName("a")

            For Each a In mainwintags
              If a.href = myApiEntry.href Then
                'oApiEntry.Add "api_type", a.ParentNode.NextSibling.LastChild.outerText
                descr_short = Replace(a.ParentNode.NextSibling.textContent, vbLf, "")
                If oApiEntry("api_descr_short") = "" Then oApiEntry.Add "api_descr_short", descr_short
              End If
            Next

            '---- Read the class_name and type (header - <cassert> (assert.h))
             class_type = obrowser.Document.getElementById("I_type").outerText
             class_name = obrowser.Document.getElementById("I_content").getElementsByTagName("h1")(0).outerText
             class_descr = obrowser.Document.getElementById("I_description").outerText

             oApiEntry.Add "api_class_name", class_name
             oApiEntry.Add "api_class_type", class_type
             oApiEntry.Add "api_class_descr", class_descr

            If oApiEntry("api_descr_short") = "" Then oApiEntry.Add "api_descr_short", "no-Description (other)"
              debug_log (myApiEntry.outerText & "|" & myApiEntry.href & "|" & oApiEntry("api_descr_short"))
              obrowser.StatusText = "Parse ... " & myApiEntry.href
            ' ----  Write to api_links file. First entry is entries_count
            If InStr(1, dupecheck, myApiEntry.outerText) = 0 Then
              dupecheck = dupecheck & ";" & myApiEntry.outerText
              oApiEntries.Add oApiEntry
              oFile_links.WriteLine "7" _
              & "|" & oApiEntry("api_name") _
              & "|" & oApiEntry("api_href") _
              & "|" & oApiEntry("api_compat") _
              & "|" & oApiEntry("api_descr_short") _
              & "|" & oApiEntry("api_class_name") _
              & "|" & oApiEntry("api_class_type") _
              & "|" & oApiEntry("api_class_descr")
            Else
              ' Sidebar bottomBox also holds a copy of itself for sidebars sort function, so just ign them.
              ' Also overloadable functions can have multiple mentions. atm we ignore those dupes too, even when they can differ in detail
              debug_log ("dupe found: " & oApiEntry("api_name"))
            End If
          End If
        Next
      End If
  Next

  oFile_links.Close

End Function

'------------------------------------------------------

Private Function fSyncBrowser() 'As Integer
'-------------
' waits for IE to signal Ready.
' Signal Ok 0 and requests timeout 1
'------------

fSyncBrowser = 1
start_time = timevalue(time)
signal_time = 1 ' wait x Seconds before signalling "waiting"
timeout = 20 ' stop after this time

Do
   actual_time = timevalue(time)
   If actual_time - start_time > timeout Then
      fSyncBrowser = 1
      Exit Function
   ElseIf actual_time - start_time > signal_time And (actual_time <> last_signal) Then
      ' Do it per second and nicely formatted :)
      debug_log (" ...waiting... " & actual_time - start_time & "seconds")
      last_signal = actual_time
   End If

  Do: Loop Until IsObject(obrowser)
    If obrowser.ReadyState = 4 and documentComplete = true Then
      fSyncBrowser = 0
      obrowser.StatusText = "Syncing ... " & iSyncCnt
      documentComplete=false
      Exit Do
    Else
      iSyncCnt = iSyncCnt + 1
    End If
  Loop

 debug_log ("Sync ready. Counter at: " & iSyncCnt)

End Function
