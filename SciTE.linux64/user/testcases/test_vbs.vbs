' build@ cscript.exe /NOLOGO //D $(FilePath) '
' Demonstrate vbScript with Events ..
'  ... Press F7 to Test...

Dim bonQuit, bConsole, oTTS

set oTTS = WScript.CreateObject("SAPI.SpVoice") 'https://msdn.microsoft.com/en-us/library/ms723602(v=vs.85).aspx
sText = "In Europa scheint die Sonne sterker in den vergangenen Jahren.. Messungen der Sonnenstrahlung offenbaren eine rote Zone, die bis nach Deutschland reicht. Was geht vor? "
idVoice = 0
sText = "As of March 2017, Wikipedia has about forty thousand high-quality articles known as Featured Articles and Good Articles that cover vital topics."
idVoice = 1

' =================== '
function main()
  if instr(1,wscript.fullName,"cscript") then bConsole=true
  ret = test_TextToSpeech(sText, idVoice)
  ret = test_comIE()
end function
'==================='

function test_comIE
Dim oIE

'---- Create object and connect the event handler in one step.
  Set oIE = wscript.CreateObject("InternetExplorer.Application","IE_")
  oIE.Navigate2("http://www.spiegel.de")
  oIE.Height = 300
  oIE.Width = 500
  oIE.Visible = 1   ' Keep visible. 

  wscript.echo("stdOut - Please close IE now....")
  do
    wscript.sleep(2000) :
    if bconsole=true then wscript.stdOut.write("-=-")
  loop until bonQuit=true

' IE_onQuit recieved
 wscript.sleep(2 * 1000)
 wscript.echo("stdOut - Okay. IE Closed ")
 wscript.sleep(2 * 1000)
 test_comIE = 0
 set oIE=Nothing
end function

' ------ Event sink -----
Sub IE_onQuit()
   wscript.echo("stdOut -> IE_onQuit Recieved")
   bonQuit=true
    oTTS.speak "OK"
End Sub

' Derived from original Sample
'https://technet.microsoft.com/de-de/ie/aa366443

'======================================'

function test_TextToSpeech(sText, idVoice)

'set oLex =WScript.CreateObject("SAPI.SpLexicon") 'https://msdn.microsoft.com/de-de/library/ms717899(v=vs.85).aspx

set oTTS.Voice = oTTS.GetVoices.Item(idVoice) '0 means default Voice'
oTTS.speak(sText)
    
for cnt = 0 to oTTS.GetVoices.count-1
  if isobject (otts.GetVoices.Item(cnt)) then 
    set voice=otts.GetVoices.Item(cnt)
    wscript.echo (voice.GetDescription) & " -> ID: " & cnt & " -> OK"
    '  wscript.echo (voice.ID)    
    set oTTS.voice = voice
    oTTS.speak "OK"
  end if 
next

'wscript.echo "Volume: " & oTTS.Volume
'wscript.echo oTTS.GetVoices.count 
'wscript.echo  oTTS.GetVoices.Item(0).GetDescription
'wscript.echo  oTTS.GetVoices.Item(1).GetDescription

end function

wscript.Quit(main)