' build@ cscript.exe /NOLOGO //D $(FilePath) '

' Demonstrate using Cscript with Events utilizing either /D or /x switch...
'  ... Press F7 to Test...

Dim oIE, bExit

Set myfso = CreateObject ("Scripting.FileSystemObject")
Set myStdOut = myfso.GetStandardStream (1)
   
' ---- Create object and connect the event handler in one step.
 Set oIE = wscript.CreateObject("InternetExplorer.Application","IE_")
 oIE.Navigate2("http://www.freedos.org")
 oIE.Height =300
 oIE.Width= 500
 oIE.Visible = 1   ' Keep visible.
 
 myStdOut.Writeline("stdOut - Please close IE now....")
  
 do :  wscript.sleep(2000) :
   myStdOut.Write("-=-")
  loop until bExit=true

wscript.sleep(2 * 1000)
myStdOut.Writeline("stdOut - Okay. IE Closed ")
wscript.sleep(2 * 1000)
 
Main=0
wscript.Quit()

' ------ Event sink -----
       
Sub IE_onQuit()
   myStdOut.Writeline("stdOut -> IE_onQuit Recieved")
   bExit=true
End Sub

' Derived from original Sample
'https://technet.microsoft.com/de-de/ie/aa366443
