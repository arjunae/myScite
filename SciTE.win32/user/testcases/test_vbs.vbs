' build@ cscript.exe /NOLOGO //D $(FilePath) '
' Demonstrate vbScript with Events utilizing either cscript /D or /X switch...
'  ... Press F7 to Test...

Dim oIE, bonQuit, bConsole, oTTS

set oTTS = WScript.CreateObject("SAPI.SpVoice") 'https://msdn.microsoft.com/en-us/library/ms723602(v=vs.85).aspx
'set oLex =WScript.CreateObject("SAPI.SpLexicon") 'https://msdn.microsoft.com/de-de/library/ms717899(v=vs.85).aspx

'wscript.echo "Volume: " & oTTS.Volume
'wscript.echo oTTS.GetVoices.count 
'wscript.echo  oTTS.GetVoices.Item(0).GetDescription
'wscript.echo  oTTS.GetVoices.Item(1).GetDescription
    
for cnt = 0 to oTTS.GetVoices.count
	if isobject (otts.GetVoices.Item(cnt)) then 
    set voice=otts.GetVoices.Item(cnt)
		wscript.echo (voice.GetDescription) & " -> OK"
    '  wscript.echo (voice.ID)    
    set oTTS.voice = voice
    oTTS.speak "OK"
  end if 
next

if instr(1,wscript.fullName,"cscript") then bConsole=true
wscript.Quit(main)

function main
'---- Create object and connect the event handler in one step.
  Set oIE = wscript.CreateObject("InternetExplorer.Application","IE_")
  oIE.Navigate2("http://www.freedos.org")
  oIE.Height =300
  oIE.Width= 500
  oIE.Visible = 1   ' Keep visible. 

  wscript.echo("stdOut - Please close IE now....")
  do
    wscript.sleep(2000) :
    if bconsole=true then wscript.stdOut.write("-=-")
  loop until bonQuit=true

' IE_Onquit recieved
 wscript.sleep(2 * 1000)
 wscript.echo("stdOut - Okay. IE Closed ")
 wscript.sleep(2 * 1000)
 main=0
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
