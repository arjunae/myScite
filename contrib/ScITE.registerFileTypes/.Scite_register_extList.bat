:: --- SciTE_Register_ExtList.cmd
::
::  -- parses entries in FileExt.List
::  -- calls .Scite_Register_Ext.cmd %1 %2
::
:: Created Nov 2015, Marcedo@HabmalneFrage.de
:: 26.06.16 - cope with writeProtected places
::
:: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
::

@echo off

 :: ... use customized CMD Terminal
 if "%1"=="" (
  reg import TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" .SciTE_Register_ExtList.bat tiny
   EXIT
 )

:: Signal batchMode for .Scite_register_ext
SET SCITE_NonInteract=1

for /F "delims=; eol=# tokens=1,2,3*" %%E in (FileExt.List) do (
 echo. %%E
 echo  :::.:::.::::.:::.::::.:::.::::.:::::.:::.::::.:::::.::
 echo  ::  [FileExt.List][%%E][%%F]
 echo  ::
 echo  :::.:::.::::.:::.::::.:::.::::.:::::.:::.::::.:::::.::
 ping 1.2.3.4 -n 1 -w 555>NUL
 call .Scite_register_ext %%E %%F  >> %tmp%\Scite_register_ext.logfile
 ) 

cd /D %tmp%\scite_tmp

:: Merge  all regFiles into one.
echo Windows Registry Editor Version 5.00>header.tmp
copy *with.scite.reg data.tmp>NUL
copy header.tmp+data.tmp scite.filetypes.register.reg>NUL

:: We assure a valid folderName, by filling spaces  in the  timestamp  (_8:33:03 -> 08.33.03)
set timestamp=%time:~0,8%
set timestamp=%timestamp: =0%
set timestamp=%timestamp::=.%

:: Move the working Folder  to our Desktop and Write a short readme for convinience

del /S /Q *.tmp *scite.reg 1>NUL
cd /D %scite_path%\steampunk
echo   Now moving files to ... %userprofile%\desktop\scite.imports.%timestamp%
echo We made it ! Your Files were placed in the Import folder :) > %tmp%\scite_tmp\readme.txt
echo Please register the filetypes you like by doubleclicking on them. >>  %tmp%\scite_tmp\readme.txt

move %tmp%\scite_tmp  %userprofile%\desktop\scite.imports.%timestamp% 1>NUL

: CleanUp

if exist %tmp%\scite_tmp (
  del /S /Q %tmp%\scite_tmp 1>NUL
  rd %tmp%\scite_tmp  1>NUL
)

:: Unset Noninteractive Mode
SET SCITE_NonInteract=0

echo - Finally - Lets ClearIconCache ;)
ie4uinit.exe -ClearIconCache

echo   -------------------------------------------
echo.
echo   Work Done - I hope you had a nice time !
echo   Please press your favorite key to be Done. 
echo.  :) Greetings to you from Deutschland, Darmstadt :) 
echo.

Pause

