' build@ cscript.exe /NOLOGO //D $(FilePath) '
' Demonstrate vbScript with Events utilizing either cscript /D or /X switch...
'  ... Press F7 to Test...

Dim oIE, bonQuit,bConsole
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
End Sub

' Derived from original Sample
'https://technet.microsoft.com/de-de/ie/aa366443
