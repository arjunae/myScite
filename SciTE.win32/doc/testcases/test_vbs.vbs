' build@ cscript.exe /NOLOGO //D $(FilePath) '
' Demonstrate vbScript with Events ..
'  ... Press F7 to Test...

Dim bonQuit, bConsole, oTTS
set oTTS = WScript.CreateObject("SAPI.SpVoice") 'https://msdn.microsoft.com/en-us/library/ms723602(v=vs.85).aspx
'sURL="http://www.yahoo.com/"
sURL="https://de.wikiquote.org/wiki/Deutsche_Sprichw%C3%B6rter"

sText = "Messungen der Sonnenstrahlung offenbaren eine rote Zone die bis nach Deutschland reicht. Was geht dort vor sich? "
sLang = "German"

'sText = "As of March 2017, Wikipedia has about forty thousand high-quality articles known as Featured Articles and Good Articles that cover vital topics."
'sLang = "English"

function test_comIE
' opens a site in ie and handles some of its Events
' Derived from original MSDN Sample
' https://technet.microsoft.com/de-de/ie/aa366443

Dim oIE
  ' -- Create object and connect the event handler in one step.
  Set oIE = wscript.CreateObject("InternetExplorer.Application","IE_")
  oIE.Navigate2(sURL)
  oIE.Height = 300
  oIE.Width = 600
  oIE.Visible = 1   ' Keep visible. 
  
  wscript.echo("stdOut - Please close IE now....")
   
  do ' -- wait for Events to be recieved
    wscript.sleep(2000) :
    if bconsole=true then wscript.stdOut.write("-=-")
  loop until bonQuit=true

  ' -- clean up on IE_onQuit
  wscript.sleep(2 * 1000)
  wscript.echo("stdOut - Okay. IE Closed ")
  test_comIE = 0
  set oIE=Nothing
end function

' ------ Event sink -----
Sub IE_NavigateComplete2(o,url)
	 'wscript.echo (o.LocationUrl & "," & sURL) 
   if o.LocationUrl  = sURL then wscript.echo("stdOut -> IE_NavigateComplete2 recieved ->" & o.Document.Location.href)
End Sub

Sub IE_onQuit()
  wscript.echo("stdOut -> IE_onQuit recieved")
  bonQuit=true
  oTTS.speak "OK"
End Sub
'======================================'

function test_TextToSpeech(sText, sLang)
' 
' sText -> Text to speak
' sLang -> Language to search for  
' returns result true or false if sLang was not found.

  'set oLex =WScript.CreateObject("SAPI.SpLexicon") 'https://msdn.microsoft.com/de-de/library/ms717899(v=vs.85).aspx

  for cnt = 0 to oTTS.GetVoices.count-1
    if isobject (otts.GetVoices.Item(cnt)) then 
      set voice=otts.GetVoices.Item(cnt)
      'wscript.echo (voice.GetDescription) & " -> ID: " & cnt & vbCr & voice.ID
      if InStr( lCase(voice.GetDescription), LCase(sLang) ) >0 then 
        set oTTS.voice = voice
        oTTS.speak(sText)
        test_TextToSpeech=true
        wscript.echo sLang, voice.GetDescription
        exit for
      else   
        set voice =otts.GetVoices.Item(0)
        test_TextToSpeech=false
      end if
    end if 
  next

  'wscript.echo "Volume: " & oTTS.Volume
  'wscript.echo oTTS.GetVoices.count 
  'wscript.echo oTTS.GetVoices.Item(0).GetDescription
  'wscript.echo oTTS.GetVoices.Item(1).GetDescription

end function


' =================== '
function main() 
dim ret

  if instr(1,wscript.fullName,"cscript") then bConsole=true

  ret= test_TextToSpeech(sText, sLang)
  if ret = vbFalse then
    wscript.Echo("Sorry, i dont speak " & sLang & ". Would you please try another language?")
  end if  
  
  ret = test_comIE()
end function
'==================='

wscript.Quit(main)
