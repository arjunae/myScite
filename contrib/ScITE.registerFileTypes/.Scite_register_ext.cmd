@echo off
:: ---------------- 
::
::   - Creates a registry import file.
::   - able to register new filetypes inclusive its mimetype and  icon 
::   - able to associate already registered filetypes with SciTE
::  
::   Syntax:
::   .Scite_register_Ext  .myExt (read: with dot and no quotes)
::   .Scite_register_Ext  .myExt  mimetype
::
::  *Outputfile has to be imported manually.*
::
::	Created Juni 2016, Marcedo@HabmalneFrage.de
:: 	URL: https://sourceforge.net/projects/scite-webdev/?source=directory
::
::  - Finds  %cmd% in actual and up to 2 parent level Directories
::  - get full qualified Path / Handle write protected Folders / Add Docs
:: 
:: ----------------

:: MSDN Docs
:: https://msdn.microsoft.com/en-us/library/windows/desktop/dd758090%28v=vs.85%29.aspx

:: Define some constants (Unicode notation)  from  %SystemRoot%\System32\imageres.dll,-1002
set ico_threeD_Paper=31,00,30,00,30,00,32,00,00,00
::1.........0........0........2 ==  31..30..30..32
set ico_toDoList=31,00,31,00,36,00,30,00,00,00
::..1.........1.......6 ..          == 31..31..36
set ico_FlipChart=31,00,30,00,33,00,30,00,00,00
::..1.........0.......3             == 31..30..33
set ico_lookingGlass=39,00,00,00
::..9....................             == 39

set ico_active=%ico_threeD_Paper%
set true=1
set false=0
:PARAMETER_SECTION
:: ------- This Batch can reside in a subdir to support a more clean directory structure
:: -- Got those shorthand strFunctions from
:: -- http://www.dostips.com/DtTipsStringOperations.php

:: Non_Interactive Mode: Dont interrupt flow.
:: Used to let this script used by other batchfiles.
:: eg .Scite_register_extList.cmd
IF [%SCITE_NonInteract%]==[%TRUE%]  (
 SET SCITE_INTERACT=%FALSE%
 REM MODE 112,30
) else (
 SET SCITE_INTERACT=%TRUE%
)

:: ---- Ensure User did set a parameter
IF [%1]==[] GOTO fail_no_params
IF %1==. (GOTO fail_no_params)
set param1=%1

 :: ---- Ensure first Char in param is  a [.] dot
set word=%param1%
set str=%word:~0,1%
IF /I NOT [%str%]==[.] GOTO fail_no_params
:: echo %str%  [should be a dot]

:: ---- Strip char . 
 set replaceWith=
 set filetype=%1
 CALL set filetype=%%filetype:.=%replaceWith%%%
 set autofile=%filetype%_auto_file
:: echo %autofile% [should read fileext_auto_file] 

:: ---- Ensure MIME type is set
IF [%2]==[] (
 set mimetype=text/plain
) else (
 set mimetype=%2
)
echo.
echo   ---------------------------------
echo  * using mimetype: %mimetype%
echo  * using handler: %autofile%
echo  * using progid: %filetype%file 
:PARSE_SECTION

:: ------- Check for and write path of %cmd% in scite_cmd
set cmd=Scite.exe

IF EXIST ..\..\%cmd% ( 
 set scite_cmd= ..\..\%cmd%
 GOTO FOUND_SCITE)
 
IF EXIST ..\%cmd% (
 set scite_cmd= ..\%cmd%
 GOTO FOUND_SCITE)

IF NOT EXIST %cmd% (
 set scite_cmd= %cmd%
 GOTO fail_filename) 

:FOUND_SCITE

::Fix Batch running on write protected Folders.
if not exist %tmp%\scite_tmp mkdir %tmp%\scite_tmp

FOR /D  %%I IN (%scite_cmd%) do echo %%~fI >%tmp%\scite_tmp\scite.tmp
set /P scite_path=<%tmp%\scite_tmp\scite.tmp

:: -- move last \  from scite_path
 set str=%scite_path%
 CALL set str=%str:\scite.exe =%
 set scite_path=%str%

:: -- replace string \ with \\ 
 set word=\\
 set str=%scite_path%
 CALL set str=%%str:\=%word%%%
 set scite_path=%str%

 :: -- replace string \\ with \\\\ to properly escape two backslashes for Scites -CWD comand"  
 set word=\\
 set str=%scite_path%
 CALL set str=%%str:\=%word%%%
 set scite_path_ext=%str%
 
:: Regedit needs the whole string enclosed with  DoubleQuotes. 
:: DoubleQuotes within the string have to be escaped with \
set scite_cmd="\"%scite_path%\\%cmd%\" \"%%1\" \"-CWD:%scite_path_ext%\""

:: Aha. Calling cd in a for loop requires the /D option
cd /D %tmp%\scite_tmp

:BACKUP_SECTON
:: -------------------------------  BACKUP  Section -----------------------------------------
::  --- savety first: Create a fresh backup of every key about to be changed ------

:: ---- Resetting backup files....

IF EXIST _*_*.bak del /Q "_*_*.bak" >NUL

echo   ---------------------------------
echo.
echo   Saftey first . About to create Backups :)
echo   [CTRL-C / STRG-C] to abort
echo.
echo   --------------------------------- 
IF [%SCITE_INTERACT%]==[%TRUE%] ( PAUSE )
echo.


:: ---- Now do the Backup
:: -- Define Filenames 
set HKCU_Classes_reg="_1_%filetype%_hnd.bak"
set HKCR_A_REG="_2_%filetype%file%_hnd.bak"
set HKCR_B_REG="_3_%filetype%_hnd.bak"
set HKCU_FileExt_REG="_4_%filetype%_ext.bak"
set HKCR_FileExt_REG="_5_%filetype%_ext.bak"

:: --- Not using EXPORT /y Switch for REG 3.0 (XP) Compatibility :p 
::   >NUL redirects StdOut,  2>NUL redirects StdErr - thanks MS !

 echo   Searchin for an existing Handler in HKCU\ and HKCR\ 
 REG query  "HKCU\Software\Classes\%autofile%\shell" >NUL 2>NUL
IF %ERRORLEVEL%===%false% (
 echo   -Backing up "HKCU\Software\Classes\%autofile%"
 REG export  "HKCU\Software\Classes\%autofile%" %HKCU_Classes_REG% >NUL 
SET HKCU_AUTOFILE=1
 ) ELSE (
SET HKCU_AUTOFILE=0
 )

REG query  "HKCR\%autofile%"  >NUL 2>NUL
IF %ERRORLEVEL%==%false% (
echo   -Backing up "HKCR\%autofile%" 
 REG export  "HKCR\%autofile%" %HKCR_B_REG% >NUL 
 SET HKCR_AUTOFILE=1
) ELSE (
SET HKCR_AUTOFILE=0
)
 
 REG query "HKCR\%filetype%file\shell\" >NUL 2>NUL
IF %ERRORLEVEL%==%false% (
 echo   -Backing up  "HKCR\%filetype%file"
 REG export "HKCR\%filetype%file" %HKCR_A_REG% >NUL
 SET HKCR_HANDLER=1
) ELSE ( 
 SET HKCR_HANDLER=0
)
 
 echo   Searchin for .%filetype% in HKCR\%.filetype% and HKCU\..FileExts\.%filetype%
 REG query "HKCR\.%filetype%" >NUL 2>NUL
IF %ERRORLEVEL%==%false% (
 echo   -Backing up "HKCR\.%filetype%"
 REG export  "HKCR\.%filetype%" %HKCR_FileExt_REG% >NUL
 SET HKCR_DOTEXT=1
) ELSE (
 SET HKCR_DOTEXT=0
)

REG query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%" >NUL 2>NUL
IF %ERRORLEVEL%==%false% (
echo   -Backing up "HKCU\....\Fileexts\" 
REG export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%"  %HKCU_FileExt_REG% >NUL
SET HKCU_DOTEXT=1
) ELSE (
SET HKCU_DOTEXT=0
)

:Backup_File_Cooking_Section

::  collects and combines generated Backupfiles 

:: IF NOT EXIST backups MD backups

REM -- Translate Unicode to ascii with type
	type _*_%filetype%*.bak >> _.%filetype%.backup.raw 2>NUL
REM -- Write Registry File header
	echo Windows Registry Editor Version 5.00 > filetypes.backup.reg 2>NUL
REM -- MixUp content to combined Backup file.
	findstr /R /V "^Windows.*" _.%filetype%.backup.raw  >> filetypes.backup.reg
	::MOVE _my*backup.REG backups >NUL
	
	
echo.
echo   ------------------------------------
echo.
echo   ...Finished cooking _my.%filetype%.backup.reg...
echo   ...Feeling fine now... Have a nice Meal :o)
echo.
echo   -------------------------------------

::CLS
:REGISTRY_SECTION 

:: --------------------------  Scite registry file Section -------------------------------------

set RegFileName=_my.%filetype%.with.scite.reg
set progid=%filetype%file

echo.
echo   OK. Next we will generate the registry import file for you.
echo.
echo   This file contains our .%filetype% association for Scite;
echo   Filename will be %RegFileName%
echo.
echo.
echo * [ NOTE: - Please check the generated file before importing by doubleclicking. ] *
echo.  

:: MSDN: perceived types: eg:, image, text, audio, and compressed.

:: --- Define Icon
:: --- (Escaping ) with three ^^^ and one ^ for the newline)
set file_icon=hex(2^^^):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,^
00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,69,00,6d,00,^
61,00,67,00,65,00,72,00,65,00,73,00,2e,00,64,00,6c,00,6c,00,2c,00,2d,00,^
%ico_active%

:: ---- Generate Registry File
if [%SCITE_INTERACT%]==[%TRUE%] echo Windows Registry Editor Version 5.00 > %RegFileName%

::----------------------------------------HKCU\......\Explorer\FileExts-------------------------------------
:: "new" Method, write a filetype and a handler to the key above
:: and list them in MRUList so Users could switch between handlers. 
::------------------------------------------------------------------------------------------------------------------

:: HKCU_DOTEXT = 1 Means we already have a handler in
:: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts

IF [%HKCU_DOTEXT%]==[%TRUE%] ( 
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%] >> %RegFileName%
 :: --- Marker
 echo "Changed_by_SciTE"="" >> %RegFileName%
 :: ---- Handler Name (eg: ext_auto_file)
 echo @="%autofile%">> %RegFileName%
 :: ---- Mime type
 echo "Content Type"="%mimetype%" >> %RegFileName%
 echo "PerceivedType"="text" >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithList] >> %RegFileName%
) 
 
IF [%HKCU_DOTEXT%]==[%TRUE%] echo "a"=%scite_cmd% >> %RegFileName%
 
IF [%HKCU_DOTEXT%]==[%TRUE%] ( 
 echo "MRUList"="a" >> %RegFileName%
:: Remove the Key to take care for the case, that it contains a write protected Hash.   
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\UserChoice] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\UserChoice] >> %RegFileName%
 echo "Progid"="%progid%" >> %RegFileName%
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo "%progid%"=hex(0^): >> %RegFileName%
) 
 
:: ----------------------------------------------------------------------------
:: But leave it empty when we don't have an autofile for the type. (then its  XP like, "oldFashion" steered)   
::----------------------------------------------------------------------------

IF [%HKCU_DOTEXT%]==[%false%] IF [%HKCU_AUTOFILE%]==[%TRUE%] (
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%] >> %RegFileName%
 :: --- Marker
 echo "Created_by_scite"="" >> %RegFileName%
 :: ---- Handler Name (eg: ext_auto_file)
 echo @="%autofile%">> %RegFileName%
 :: ---- Mime type
 echo "Content Type"="%mimetype%" >> %RegFileName%
 echo "PerceivedType"="text" >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\shell] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\shell\open] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\shell\open\command] >> %RegFileName%
)
 
IF [%HKCU_DOTEXT%]==[%false%] IF [%HKCU_AUTOFILE%]==[%TRUE%] echo @=%scite_cmd% >> %RegFileName%
 
IF [%HKCU_DOTEXT%]==[%false%] IF [%HKCU_AUTOFILE%]==[%TRUE%] ( 
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithList] >> %RegFileName%
 echo "a"=%autofile% >> %RegFileName%
 echo "MRUList"="a" >> %RegFileName%
:: Remove the Key to take care for the case, that it contains a write protected Hash.   
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\UserChoice] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\UserChoice] >> %RegFileName%
 echo "Progid"="%progid%" >> %RegFileName%
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo "%progid%"=hex(0^): >> %RegFileName%
)

::---------------------------------------HKCU\Software\Classes----------------------------------
:: Again....If we use "old Fashioned" Style we  mark that by using another String  instead.
::-------------------------------------------------------------------------------------------------------
  
 IF [%HKCU_AUTOFILE%]==[%false%] SET autofile=%progid%

 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%] >> %RegFileName%
 echo @=Scite .%filetype% Handler >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\open] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\open\command] >> %RegFileName%
 IF %HKCU_AUTOFILE%==%TRUE%  echo @=%scite_cmd% >> %RegFileName%
 echo "changed_by_scite"="" >> %RegFileName%
 echo "EditFlags"=hex:00,00,00,00 >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\edit] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\edit\command] >> %RegFileName%
 echo @=%scite_cmd% >> %RegFileName%
  
:: ---  ICON
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\DefaultIcon] >> %RegFileName%
 echo @=%file_icon% >> %RegFileName%
 
::---------------------------------------------------------------------------------------------------------------------------
:: ---Now for  XP / "old fashioned" Method, write a fileext and a handler directly to HKCR. 
::---------------------------------------------------------------------------------------------------------------------------
 
IF [%HKCR_DOTEXT%]==[%TRUE%] (
 echo [HKEY_CLASSES_ROOT\.%filetype%] >> %RegFileName%
 echo "Edited_by_scite"="" >> %RegFileName%
:: ---- Handler Name (eg: ext_auto_file)
IF [%HKCU_AUTOFILE%]==[%TRUE%] echo @="%autofile%">> %RegFileName%
IF [%HKCU_AUTOFILE%]==[%false%] echo @="%progid%">> %RegFileName%
:: ---- Mime type
 echo "Content Type"="%mimetype%" >> %RegFileName%
 echo "PerceivedType"="text" >> %RegFileName%
 echo [HKEY_CLASSES_ROOT\.%filetype%\UserChoice] >> %RegFileName%
 echo "Progid"="%progid%" >> %RegFileName%
)

 ::echo [-HKEY_CLASSES_ROOT\.%filetype%\OpenWithProgids] >> %RegFileName%
 ::echo [HKEY_CLASSES_ROOT\.%filetype%\OpenWithProgids] >> %RegFileName%
 ::echo "%progid%"=hex(0^): >> %RegFileName%
 ::echo "%progid%"="%progid%" >> %RegFileName%
 
 :FINALIZE_SCTION

::IF NOT EXIST import MD import >NUL
::IF EXIST _*.REG  MOVE _*.REG import >NUL
 
 echo   -------------------------------------------
 echo.
 echo   Finished writing %RegFileName%
 echo.  
 echo   I hope you had a nice time !
 echo   Please press your favorite key to be Done. 
 echo.  :) Greetings to you from Deutschland, Darmstadt :) 
 echo.
 
 :: ----  Note down how to call scite exe from anywhere on the system. 
 :: set /P scite_path=<scite.tmp
 :: echo. > _scite.read.me.path.txt
 :: echo "Hint: Use this parameters to open scite from anywhere:" >> _scite.read.me.path.txt
 :: echo %scite_path% "%%1" "-cwd:%scite_path_ext%" >> _scite.read.me.path.txt

:CLEANUP_SECTION
 :: ---------------- Clean UP and Fin.--------------------------
 del /Q  *.tmp 2>NUL 
 del /Q  *.bak 2>NUL 
 del /Q  *.raw 2>NUL 
 
IF [%SCITE_INTERACT%]==[%TRUE%] echo   ==Temporary storing Files to  ... "%tmp%\scite_tmp"==

cd /D %scite_path%\SteamPunk

 :: Fix Batch running on write protected Folders.
 set timestamp=%TIME:~0,8%
 set timestamp=%timestamp: =0%
 set timestamp=%timestamp::=.%

:: This Batch gets called multiple times in nonInteractive  Mode from  ".Scite_register_extList.bat"
:: We assure a valid folderName, by filling spaces  in the  timestamp  (_8:33:03 -> 08.33.03)
IF [%SCITE_INTERACT%]==[%TRUE%]  (
 echo   Writing files to ... %userprofile%\desktop\scite.imports.%timestamp%
 move %tmp%\scite_tmp  %userprofile%\desktop\scite.imports.%timestamp% >NUL 2>NUL
)

IF [%SCITE_INTERACT%]==[%TRUE%] IF EXIST %tmp%\scite_tmp (
  del /S /Q %tmp%\scite_tmp>NUL 2>NUL 
  rd %tmp%\scite_tmp>NUL 2>NUL 
 PAUSE >NUL
)

 echo.  Fin.
 echo   -------------------------------------------

GOTO end

:fail_filename
 echo Please fix: %cmd% was'nt found or did'nt match %%cmd
 echo -- Try to copy this file to scites root dir --
IF [%SCITE_INTERACT%]==[%TRUE%] (PAUSE)
GOTO end

:fail_no_params
IF [%SCITE_INTERACT%]==[%FALSE%] goto end
echo.
echo -----------------  Help   -------------------------------
echo.                
echo   - able to register new filetypes inclusive its Icon.
echo   - able to associate already registered filetypes with SciTE
echo   - Creates a registry import file.
echo.
echo  * Syntax: .Scite_register_fileExt [.FileExt] [optional MimeTyp]
echo.
echo            *  Example  *
echo   .Scite_register_Ext .me
echo   .Scite_register_Ext .myfancy text/plain
echo.
echo.
echo  *  Would create a regfile, that associates Scite  
echo  *  with filetypes context menu "edit"                
echo  
echo.
echo   .... * feeling Fine * :) 
echo.
echo  First Param given was: %1
echo  Second Param given was: %2
echo.
echo ---------------------------------------------------------

echo - finally - Lets ClearIconCache ;)
ie4uinit.exe -ClearIconCache

:END
