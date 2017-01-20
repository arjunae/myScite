@echo off

::--::--::--::--Steampunk--::-::--::--::
:: -- Scite.createExtList.cmd 
::
::  -- parses entries in FileExt.List
::  -- Creates a human readable filetypes.reg file by calling
::  -- .scite.forceExt.cmd %1 %2
::
:: Created Okto 2015, Marcedo@HabmalneFrage.de
:: 26.06.16 - cope with writeProtected places
:: 31.10.16 - cleanUp
::
:: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
::
::--::--::--::--Steampunk--::-::--::--::

:WRAPPER
:: Use customized CMD Terminal
if "%1"=="" (
 reg import TinyTonCMD\TinyTonCMD.reg
 start "TinyTonCMD" scite.createExtList.cmd tiny
 EXIT
)

:MAIN_SECTION
:: Signal batchMode for .Scite.force_ext
SET SCITE_NonInteract=1

for /F "delims=; eol=# tokens=1,2,3*" %%E in (FileExt.List) do (
 echo. %%E
 echo  :::.:::.::::.:::.::::.:::.::::.:::::.:::.::::.:::::.::
 echo  ::  [FileExt.List][%%E][%%F]
 echo  ::
 echo  :::.:::.::::.:::.::::.:::.::::.:::::.:::.::::.:::::.::
 ping 1.2.3.4 -n 1 -w 555>NUL
 call scite.createExt.cmd %%E %%F  >> %tmp%\scite.createExtList.logfile
) 
cd /D %tmp%\scite_tmp

:: Create regedit Header 
echo Windows Registry Editor Version 5.00>header.tmp
copy *with.scite.reg data.tmp>NUL

:: create / reset Program Key 
echo [-HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe] >>data.tmp
echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe] >>data.tmp
echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell] >>data.tmp
echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell\open] >>data.tmp
echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell\open\command] >>data.tmp
echo @=%scite_cmd% >>data.tmp
echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\SupportedTypes] >>data.tmp
echo ".*"="">>data.tmp

:: Now, merge all regFiles into one.
copy header.tmp+data.tmp scite.filetypes.register.reg>NUL

:: We assure a valid folderName, by filling spaces  in the  timestamp  (_8:33:03 -> 08.33.03)
set timestamp=%time:~0,8%
set timestamp=%timestamp: =0%
set timestamp=%timestamp::=.%
set timestamp=%timestamp%_%RANDOM%

:: Move the working Folder  to our Desktop and Write a short readme for convinience

del /S /Q *.tmp *scite.reg 1>NUL
cd /D %scite_path%\installer\steampunk
echo   Now moving files to ... %userprofile%\desktop\scite.imports.%timestamp%
echo We made it ! Your Files were placed in the Import folder. > %tmp%\scite_tmp\readme.txt
echo The following step could be automated too, but i like userChoices :)>> %tmp%\scite_tmp\readme.txt
echo So, please register the filetypes in scite.filetypes.register.reg with rightClick::Import >>  %tmp%\scite_tmp\readme.txt
echo enjoy, Arjunae>> %tmp%\scite_tmp\readme.txt

move "%tmp%\scite_tmp" "%userprofile%\desktop\scite.imports.%timestamp%" 1>NUL

:CLEANUP_SECTION
:: Delete tempFiles / Unset Noninteractive Mode
SET SCITE_NonInteract=0

if exist %tmp%\scite_tmp (
  del /S /Q %tmp%\scite_tmp 1>NUL
  rd %tmp%\scite_tmp  1>NUL
)

echo   -------------------------------------------
echo.
echo   Work Done - I hope you had a nice time !
echo   Please press your favorite key to be Done. 
echo.  :) Greetings to you from Deutschland, Darmstadt :) 
echo.

Pause
