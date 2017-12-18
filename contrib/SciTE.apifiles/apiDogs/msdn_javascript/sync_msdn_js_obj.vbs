' build@ cscript.exe /NOLOGO //D $(FilePath)
'-----------------------------------------------------------------------------
'   MSDN-Fetcher;  Syncs Content with https://msdn.microsoft.com/
'   Status:  20151123 Redo Sync, Add oApiDescr. oApiParams, use IE StatusBar
'   vba.module - works on VbScript too.
'   Marcedo[at]gmx[dot]net
'

Dim sFolder, sFileName ' As String
Dim iSyncCnt 'as Long

Dim htmldoc 'As mshtml.htmldocument
Dim ofile_log 'As Scripting.TextStream
Dim ofile_links
Dim oMyCatList 'As Collection

'Sub vba_msdn()

    Dim result ' As String
    Dim obrowser ' As InternetExplorer
    Set obrowser = CreateObject("InternetExplorer.Application")

    obrowser.Visible = True
    obrowser.Silent = True
    obrowser.StatusBar = True

' URL-Laden
' ---  Javascript Properties https://msdn.microsoft.com/en-us/library/xyad316h(v=vs.94).aspx
' --- Javascript Objekts Link:' https://msdn.microsoft.com/en-us/library/htbw4ywd(v=vs.94).aspx
  obrowser.Navigate2 ("https://msdn.microsoft.com/en-us/library/htbw4ywd(v=vs.94).aspx")
  sFolder = "msdn_js_api"
  sFileName = "msdn.js.api.raw"     

    result = fParseResults(obrowser)
    obrowser.Quit
    Set obrowser = Nothing

  MsgBox (" Fini -> Did " & result & " Entries :)")

'End Sub

'---------------------------------------------------------------------

Function fParseResults(obrowser)

    Dim fso 'as Scripting.FileSystemObject
    Dim sidebar 'As MSHTML.HTMLDivElement
    Dim oBtn 'As MSHTML.HTMLElementCollection
    Dim sCatName 'as String
    
  result = waitforBrowser(obrowser)
  
  Do
    Set htmldoc = obrowser.Document
    'MsgBox( obrowser.Document.body.innerhtml)
  Loop Until htmldoc.body.innerhtml = obrowser.Document.body.innerhtml
 
'---- prepare textfiles
  Set fso = CreateObject("Scripting.FileSystemObject")
'  Set ofile_log = fso.CreateTextFile("sync_msdn.log")
  
'--- undocumented: redir log messages to console (use wscript //X) 
  Set myfso = CreateObject ("Scripting.FileSystemObject")
  Set ofile_log = myfso.GetStandardStream (1)
  
'----  do some error checking
  If IsObject(htmldoc.getElementById("leftNav")) Then
      Set sidebar = htmldoc.getElementById("tocnav")
  Else
      Exit Function
  End If
  
'---- open all Folders (to load all Data into Browser)
  Set htmldoc = obrowser.Document

  For Each oBtn In htmldoc.getElementsByClassName("toc_collapsed")
      sCatName = oBtn.ParentNode.innerText
      oBtn.Click
      res = waitforBrowser(obrowser)
      obrowser.StatusText = "... Opening ... " & sCatName
      ofile_log.Write "...Opening Category... " & sCatName & vbCrLf
      Set oObjList = oBtn.parentElement
  Next
  
  ofile_log.Write ".., succesfully opened all Categories ... " & vbCrLf & vbclf
  
  'Set ocatname = sidebar.getElementsByClassName("tocPadding")(0)
  Set ocatname = htmldoc.getElementsByClassName("tocPadding")(0)
  
  Do
  res = waitforBrowser(obrowser)
  Set oMyCatList = obrowser.Document.getElementsByClassName("toclevel")
    Do: Loop Until Not (Nothing Is oMyCatList(0))
    obrowser.StatusText = "Collecting soap Data: " & oMyCatList.Length
  Loop Until obrowser.Document.getElementsByClassName("toclevel")(0).innerhtml = oMyCatList(0).innerhtml

  MsgBox ("Ready to start parsing. You can stop anytime and resume later, if you need to.")
  
'----  Nice Catch - goodby redim preserve
  Set oArrApiDoc = CreateObject("System.Collections.ArrayList")
  ofile_log.Write "Collecting Soap Menuentries: " & vbCrLf
  
'---- Fetch all previsiously loaded data from browser to above Objects
  For Each oObj In oMyCatList

    Dim oApiLink, oApiName, oApiFileName, oApiHref, oApiPos, oApiId
    Dim sReserved, sCharReserved, strPos
    
  '----Look and collect freshly arrived Soap Data.
    ofile_log.Write "."
  
    res = waitforBrowser(obrowser)
    iCntlast = oMyCatList.Length
    Set oMyCatList = obrowser.Document.getElementsByClassName("toclevel")
    If iCntlast <> oMyCatList.Length Then ofile_log.Write oMyCatList.Length
  
  '---- could use a class here, but using sortedList for ExcelVBA Compatibility
      Set oApiLink = CreateObject("System.Collections.SortedList")
      
  
        oApiName = oObj.all(1).innerText
       ' if len (oApiName)>1 exit for
      
      icharCnt = InStr(oApiName, " ")
      if icharCnt = 0 then iCharCnt =len(oapiname)     
      
    '---- Strip suffix after first space -
       oApiName = Left(oApiName, iCharCnt - 1)
      oApiHref = oObj.all(1).href
  
    ' ---- Get ApiLink from Start till last /
      oApiId = StrReverse(oApiHref)
      oApiPos = InStr(oApiId, "/")
      oApiId = Left(oApiId, oApiPos - 1)
      oApiId = StrReverse(oApiId)
      oApiId = Replace(oApiId, ".aspx", "")
      
      sMenuLevel = oObj.getattribute("data-toclevel")
      If sMenuLevel = 1 Then sCurrentCat = oObj.all(1).innerText
      
    '---- CleanUp and Set Filename
      oApiFileName = oApiId & "--" & sCurrentCat & "--" & oApiName
  
    '---- Iterate List of OS Reserved Chars
      sReserved = ";<>!|?:=/\*"
  
      For iCharPosReserved = 1 To Len(sReserved)
        sCharReserved = Mid(sReserved, iCharPosReserved, 1)
        strPos = InStr(1, oApiFileName, sCharReserved)
      '---- clean oApiFileName
        If strPos > 3 Then
      '---- try to match a (
        strTmp = InStr(strPos - 4, oApiFileName, "(")
        If strTmp > 0 Then strPos = strTmp
        
        oApiFileName = Replace(oApiFileName, sCharReserved, "")
        End If
    Next

  '---- Create an entry in a SortedList
    oApiLink.Add "oApiMenuLevel", sMenuLevel
    oApiLink.Add "oApiName", oApiName
    oApiLink.Add "oApiHref", oApiHref
    oApiLink.Add "oApiCategory", sCurrentCat
    oApiLink.Add "oApiId", oApiId
    oApiLink.Add "oApiFileName", oApiFileName

  '---- copy over to ApiList Array  -  works like charm
    oArrApiDoc.Add oApiLink
    ' Debug.Print oArrApiDoc(0)("oApiHref")
  Next

  ofile_log.Write vbCrLf & "Finished Parsing Menu. I parsed " & oArrApiDoc.Count & " Entries." & vbCrLf
  Call CreateDocs(sFolder, ofile_log, obrowser, oArrApiDoc)
    
  ofile_log.Close
    
  fParseResults = oArrApiDoc.Count
  
End Function

'-----------------------------------------------------------------------------------------------

Sub CreateDocs(sFolder, ofile_log, obrowser, oArrApiDoc)

'
' Creates a Folder with downloaded MSDN Content
' Takes browserObject and an Array with URLs to fetch as Param
'
'
  
  Dim oFldApiDoc ' As Scripting.TextStream
  Dim ofs 'As Scripting.FileSystemObject
  
  iFetchCnt = 0: iSyncedCnt = 0
  
  Set ofs = CreateObject("Scripting.FileSystemObject")
  ofile_log.Write ("About to fetch ApiDocs now -> A full Sync takes up to 20 Minutes, so how about some Coffee ?") & vbCrLf
  
  If Not ofs.FolderExists(sFolder) Then
    Set oFldApiDoc = ofs.createFolder(sFolder)
    Set ofile_links = ofs.CreateTextFile(sFileName)
  Else
    Set oFldApiDoc = ofs.getFolder(sFolder)
    Set ofile_links = ofs.OpenTextFile(sFileName, 8) '=ForAppending
  End If
  
  ofile_log.Write "Syncing with MSDN:" & vbCrLf
    
  For Each docEntry In oArrApiDoc
    ofile_log.Write "*"
    sApiSyntax = ""
    sApiPArams = ""
    sApiDesc = ""
       
  '---- check if MSDN ApiId has changed.
    If ofs.FileExists(oFldApiDoc & "\" & docEntry("oApiId") & "*.HTML") Then
      ' msgbox "MSDN API IDs Changed. Please clear Folder before you continue"
      ofile_log.Write "MSDN API IDs Changed. Please clear Folder before you continue" & vbCrLf
    End If
      
  '---- check if Apientry is already in our Pocket before fetching.
    If Not ofs.FileExists(oFldApiDoc & "\" & docEntry("oApiFileName") & ".HTML") Then
    
      result = parseMainWin(obrowser, docEntry)
      
      FileName = oFldApiDoc & "\" & docEntry("oApiFileName") & ".html"
      sHeader = ("<html>" & obrowser.Document.head.outerhtml)
      sBody = (obrowser.Document.body.outerhtml & "</html>")
            
      result = SaveTextData(FileName, sHeader & sBody, "")
      iFetchCnt = iFetchCnt + 1
    Else
      obrowser.StatusText = ".... Alread Synced ... " & docEntry("oApiFileName") & vbCrLf
      iSyncedCnt = iSyncedCnt + 1
  End If
Next

ofile_log.Write vbCrLf & "_________________________________________________________" & vbCrLf

ofile_log.Write "Entries parsed: " & oArrApiDoc.Count & vbCrLf
ofile_log.Write "Already in sync: " & iSyncedCnt & vbCrLf
ofile_log.Write "Newly fetched: " & iFetchCnt & vbCrLf
ofile_log.Write "Hope you had a nice time ;)"

  ofile_links.Close
   
End Sub

Private Function parseMainWin(obrowser, docEntry)
      
  obrowser.Navigate2 (docEntry("oApiHref"))
  result = waitforBrowser(obrowser)
  obrowser.StatusText = ".... Parsing ... " & docEntry("oApiName")
 
' ---- get api Description
on error resume next
do
  sApiDesc = obrowser.Document.getElementById("mainBody").all(1).innerText
loop  until length(sApiDesc) > 0
on error goto 0

  sApiDesc = Replace(sApiDesc, vbCrLf, "")
  sApiDesc = Replace(sApiDesc, ";", ",")
    
  Set oapiWarn = obrowser.Document.getElementsByClassName("alertTitle")
  If oapiWarn.Length > 0 Then sApiDesc = sApiDesc & " ** "
  sApiDesc = Replace(sApiDesc, vbCrLf, "\t\n")
  docEntry.Add "oApiDesc", sApiDesc
  
' ---- get Syntax Sample, if any and - please - choose the matching one :)
  If Not (Nothing Is obrowser.Document.getElementsByTagName("pre")) Then
    For Each oSyntax In obrowser.Document.getElementsByTagName("pre")
      If InStr(oSyntax.innerText, docEntry("oApiName")) Then
        sApiSyntax = oSyntax.innerText
        Exit For
      End If
    Next
  End If
  
'---- replace crLf on multiline Samples
  sApiSyntax = Replace(sApiSyntax, vbCrLf, "\t\n")
  sApiSyntax = Replace(sApiSyntax, ";", ",")
  docEntry.Add "oApiSyntax", sApiSyntax
      
' ---- Collect Api parameter
  Set oApiParamsRaw = obrowser.Document.getElementsByTagName("dt")
  sApiPArams = "("
  
  For Each param In oApiParamsRaw
    sApiPArams = sApiPArams & param.innerText & " "
  Next
  
' ---- add Parameter separator "," and write to array
  sApiPArams = sApiPArams & ")"
  sApiPArams = Replace(sApiPArams, " )", ")")
  If oApiParamsRaw.Length > 1 Then sApiPArams = Replace(sApiPArams, " ", ",")
  docEntry.Add "oApiParams", sApiPArams

  '--- Cook a nice meal "8 Output File-Steaks" for all please.
    ofile_links.Write _
    docEntry("oApiMenuLevel") & " ; " _
    & docEntry("oApiId") & " ; " _
    & "9" & " ; " _
    & docEntry("oApiCategory") & " ; " _
    & docEntry("oApiName") & " ; " _
    & docEntry("oApiParams") & " ; " _
    & docEntry("oApiDesc") & " ; " _
    & docEntry("oApiHref") & " ; " _
    & docEntry("oApiSyntax") & vbCrLf
  
   'uncomment vba: Debug.Print docEntry("oApiMenuLevel") & " ; " &  docEntry("oApiId") & " ; "  '& "9" & " ; "  & docEntry("oApiCategory") & " ; " & docEntry("oApiName") & " ; " & docEntry("oApiParams") & " ; "  & docEntry("oApiDesc") & " ; " & docEntry("oApiHref") & " ; " & docEntry("oApiSyntax")

End Function

Private Function SyncIE(obrowser)

  Do: iSyncCnt = iSyncCnt + 1: Loop Until obrowser.Document.ReadyState = "complete"
  
  obrowser.StatusText = "Syncing ... " & iSyncCnt
  Set htmldoc = obrowser.Document
  
End Function

Private Function waitforBrowser(obrowser)
 
 ' only with WSH
 ' wscript.sleep ("300")
  Do: Loop Until IsObject(obrowser)
  Do: iSyncCnt = iSyncCnt + 1: Loop Until obrowser.Busy = False
  Do: Loop Until obrowser.ReadyState = 4
  Do: Loop Until Not (obrowser.Document.body Is Nothing)

  Call SyncIE(obrowser)

End Function


Function SaveTextData(FileName, Text, CharSet)
'
' As Fso.opentextfile sucked on some content - found this code, using ADODB.Stream.
'   PublicDomain from http://www.motobit.com/tips/detpg_read-write-binary-files/
'    thank you - Works really well !
'
      
  Const adTypeText = 2
  Const adSaveCreateOverWrite = 2
  
  'Create Stream object
  Dim BinaryStream
  Set BinaryStream = CreateObject("ADODB.Stream")
  
  'Specify stream type - we want To save text/string data.
  BinaryStream.Type = adTypeText
  
  'Specify charset For the source text (unicode) data.
  If Len(CharSet) > 0 Then
    BinaryStream.CharSet = CharSet
  End If
  
  'Open the stream And write binary data To the object
  BinaryStream.Open
  BinaryStream.WriteText Text
  
  'Save binary data To disk
  BinaryStream.SaveToFile FileName, adSaveCreateOverWrite
  
End Function
