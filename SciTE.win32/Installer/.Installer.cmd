@echo off
mode 90,20
chcp 65001 1>NUL
REM  ::--::--::--::--Steampunk--::-::--::--::
REM
REM  Add Scite to Explorers Context Menu. (for win7+)
REM  -> Provides "open with SciTE" and "open SciTE here" 
REM  -> Register SciTE to Windows known Applications List
REM  - Creates a regfile which can either be manually or automagically imported -
REM  - Parses SciTE understood Filetypes and Registers them with Explorer - 
REM
REM :: Created Jul 2016, Marcedo@HabmalneFrage.de
REM :: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
REM :: License BSD-3-Clause
REM :: Application Registering Reference: https://msdn.microsoft.com/en-us/library/windows/desktop/ee872121(v=vs.85).aspx
REM
REM - Aug16 - Search for %cmd% in actual and up to 2 parent Directories / Use full qualified path. 
REM - Okto16 - create / reset Program Entry RegistryKey  
REM - Nov16 - reactos fix
REM - Mai17 - "open Scite Here"
REM - Mar18 - "ability to register myScites Filetypes"
REM 
REM ::--::--::--::--Steampunk--::-::--::--::

REM Normally, the keyword REM identifies a comment line, but we also use the defacto shortform ::
REM Exception: some Dos parsers dont fully support :: within loops, so definately use REM there.

 pushd %~dp0%

:sub_main
 REM Choose to enable WorkArounds for Reactos 0.4.8. Valid Values: 0/1 
 set FIX_REACTOS=0
 if [%1]==[1] set FIX_REACTOS=1
 set file_name=SciTE.exe
 set scite_filepath=empty

 :: -- Check for and write path of %file_name% in scite_filepath (search up to 10Dirs up)
 :loop
   set /a dir_count += 1
   if %dir_count% geq 10 (goto end_loop) else (cd ..)
   if exist "%file_name%" (
    set scite_filepath="%cd%\%file_name%"
    set scite_path="%cd%"
    goto end_loop
    )	
   goto loop 
 :end_loop
 popd
 IF NOT EXIST %scite_filepath% ( call :sub_fail_cmd ) else ( call :sub_create_file ) 

 REM  -- Code Continues here --
 echo. --
 echo. -- About to add "open with SciTE" and "open SciTE here" to Explorers Context Menu. 
 echo. --
 echo. 
 
 :: Give the User the option to manually edit/import the generated File.
 :: When "manual Installation" has been chosen, just copy the generated reg import file to currentUsers Desktop.
 
 if [%FIX_REACTOS%] equ [1] Pause && ECHO. && SET ERRORLEVEL=2
 if [%FIX_REACTOS%] equ [0] choice /C AM /M " -- Press [A] for automatic Install or [M] If you want to do that manually" 
 
 if %ERRORLEVEL% == 1 reg import %regfile%
 if %ERRORLEVEL% == 2 (
  echo. .... Ok- Now opening the Import File for editing .... 
  echo. .... Please press your favorite key when done. 
  %scite_filepath% "%regfile%"
  pause> NUL
  copy "%RegFile%" .scite.to.contextMenu.reg>NUL
  move /Y "%regfile%" "%userprofile%\desktop">NUL
  echo.
  echo   ---------------------------------------------
  echo. .... copied to %userprofile%\desktop
  echo   ---------------------------------------------
  echo.
 )
 if [%FIX_REACTOS%]==[1] goto freunde 
 if %ERRORLEVEL% neq 0 goto sub_fail_reg
 
 :: Ask if the User wants FileType Registration
 if [%FIX_REACTOS%]==[0] ( 
  echo  .. Register SciTE with understood Filetypes?
  echo  .. (Doesnt overwrite already made associations)  
  choice /C YN /M " -- [Yes/No]" 
  :: Parses all .properties files and Registers their contained Filetypes 
  if %ERRORLEVEL% == 1 (
    call scite_filetypes /quite %scite_filepath%
    if %ERRORLEVEL% == 0 goto freunde
  )
 )
 
 :: -- Clean up --
 del /Q %tmp%\scite.tmp 2>NUL
 goto :freunde
:end_sub_main
 
:sub_create_file

 :: -- scite_path: remove doublequotes
 set word=
 set str=%scite_path%
 CALL set str=%%str:"=%word%%%
 set scite_path=%str%

 :: -- scite_path: Escape Backslashes
 set word=\\
 set str=%scite_path%
 CALL set str=%%str:\=%word%%%
 set scite_path=%str%

 :: -- properly escape two backslashes for Scites -CWD comand"  
 set word=\\\\
 set str=%scite_path%
 CALL set str=%%str:\\=%word%%%
 set scite_path_cwd=%str%

 REM -- Define usable comand line options for SciTE here
 set RegFile=%tmp%\scite_install.reg
 set scite_cmd_cwd=-CWD:%scite_path_cwd%
 set scite_cmd_open=-open new.txt
 set file_namepath=\"%scite_path%\\%file_name%\"  
 
 REM Short Explanation
 REM -- Finally, write the .reg file, \" escapes double quotes
 REM -- using the safe way here. Windows will automatically update all needed Entries. 
 echo Windows Registry Editor Version 5.00 > %RegFile%
 echo. >> %RegFile%
 echo ; -- Update ContextMenu "Open With Scite" and "Open Scite Here" >> %RegFile%
 echo [-HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE\command] >> %RegFile% 
 echo @="%file_namepath% \"%%1\"" >> %RegFile%
 echo [-HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\scite] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\scite] >> %RegFile%
 echo @="Open SciTE here" >> %RegFile%
 echo "Icon"="%scite_path%\\%file_name%,0" >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\scite\command] >> %RegFile%
 echo @="%file_namepath% %scite_cmd_open%" >> %RegFile%
 echo. >> %RegFile%
 
:: The following simple mechanism registers Scite to Windows known Applications.
 echo ; -- Update Program Entry >> %RegFile%
 echo [-HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe] >> %RegFile%
 echo "FriendlyAppName"="Scintilla based TExteditor" >> %RegFile%
 echo "InfoTip"="SCIntilla based TExteditor" >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\Application] >> %RegFile%
 echo "ApplicationCompany"="Scintilla.org Scite" >> %RegFile%
 echo "ApplicationName"="SciTE" >> %RegFile%
 echo "ApplicationDescription"="Scintilla based Texteditor" >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\DefaultIcon] >> %RegFile%
 echo @="%scite_path%\\%file_name%,0" >> %RegFile%
 echo. >> %RegFile%
 
:: Include Scite within the Explorers Context menu "open With" list 
:: When a System already has some Apps installed, the new SciTE Entry will appear within the ("more Apps") submenu.   
 echo ; -- Update Explorers "open with" list >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell\open] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell\open\command] >> %RegFile%
 echo @="%file_namepath% \"%%1\"" >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\SupportedTypes] >> %RegFile%
 echo ".*"="">> %RegFile%
 echo. >> %RegFile%
 
:: Register Scite to be known for windows "start" command
:: https://msdn.microsoft.com/en-us/library/windows/desktop/ee872121(v=vs.85).aspx
 echo ; -- Register Scite to be known for windows "start" command >> %RegFile%
 echo [-HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\SciTE.exe] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\SciTE.exe] >> %RegFile%
 echo @="%file_namepath%" >> %RegFile%
 echo "Path"="%scite_path%" >> %RegFile%
 echo. >> %RegFile%
 
 echo ; -- Uninstall >> %RegFile%
 echo ; [-HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE]  >> %RegFile%
 echo ; [-HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\scite]>> %RegFile%
 echo ; [-HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\SciTE.exe] >> %RegFile%
 
 :: echo ..... Finished writing to  %RegFile% ....
 exit /b 0
:end_sub_create_file

:sub_fail_cmd
 echo.
 echo Please fix: %file_name% was'nt found or Filename did'nt match variable "file_name"
 echo ...Try to copy this file to scites root dir...
 echo ...any key...
 pause >NUL
exit
:end_sub_fail_cmd

:sub_fail_reg
 echo.
 echo ... User Aborted registry Import
 echo ... No changes were made ...
 echo ... any key ...
 pause >NUL
exit
:end_sub_fail_reg

:freunde
 echo   ---------------------------------------------
 echo   Work Done - I hope you had a nice time !
 echo   A Backup has been stored in: %Userprofile%
 echo.  :) Greetings to you from Deutschland, Darmstadt :) 
 echo   --------------------------------------------
 echo.
 :: wait some time...
 echo Now, please press your favorite key to be Done. HanD! 
 pause >NUL
:end_sub_freunde