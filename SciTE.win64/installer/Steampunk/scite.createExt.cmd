@echo off
::--::--::--::--Steampunk--::-::--::--::
::  
::   Syntax:
::   scite.createExt  .myExt (read: with dot and no quotes)
::   scite.createExt  .myExt  mimetype
::
::   - Creates a human readable registry import file, which can be imported manually-
::   - able to register new filetypes inclusive its mimetype and  icon 
::   - able to associate already registered filetypes with SciTE
::
::	Created Juni 2016, Marcedo@HabmalneFrage.de
:: 	URL: https://sourceforge.net/projects/scite-webdev/?source=directory
::
::  - Finds  %cmd% in actual and up to 2 parent level Directories
::  - get full qualified Path / Handle write protected Folders / Add Docs
:: 
::--::--::--::--Steampunk--::-::--::--::

 set true=1
 set false=0
 
 REM WorkAround Reactos 0.4.2 Variable Expansion Bug.
 set FIX_REACTOS=0
 
:: MSDN Docs
:: https://msdn.microsoft.com/en-us/library/windows/desktop/dd758090%28v=vs.85%29.aspx
:: https://msdn.microsoft.com/en-us/library/windows/desktop/cc144104(v=vs.85).aspx

:: Define some constants (Unicode notation)  
:: from %SystemRoot%\System32\imageres.dll,-1002
::1.........0........0........2 ==  31..30..30..32
set ico_threeD_Paper=31,00,30,00,30,00,32,00,00,00
::..1.........1.......6 ..          == 31..31..36
set ico_toDoList=31,00,31,00,36,00,30,00,00,00
::..1.........0.......3             == 31..30..33
set ico_FlipChart=31,00,30,00,33,00,30,00,00,00
::..9....................             == 39
set ico_lookingGlass=39,00,00,00

set ico_active=%ico_threeD_Paper%

:PARAMETER_SECTION
:: ------- This Batch can reside in a subdir to support a more clean directory structure
:: -- Got those shorthand strFunctions from
:: -- http://www.dostips.com/DtTipsStringOperations.php

:: -- Non_Interactive Batch-mode: Dont interrupt flow.
:: -- allow the script been called in a loop from other batchfiles.
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

:SEARCH_SCITE
:: ------- Check for and write scites path registry escaped to %scite_cmd%
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
:: set scite_cmd="\"%scite_path%\\%cmd%\" \"%%1\" \"-CWD:%scite_path_ext%\""
:: with scite_webdevs (3.6.4) portability patch in we" doesnt need cwd anymore 
set scite_cmd="\"%scite_path%\\%cmd%\" \"%%1\""

:: Aha. Calling cd in a for loop requires the /D option
cd /D %tmp%\scite_tmp

:BACKUP_SECTON
:: -------------------------------  BACKUP  Section -----------------------------------------
::  --- savety first: Create a fresh backup of every key about to be changed ------
::
::  takes 
::    SCITE_INTERACT ; %true% = 1 (run silently in BatchMode)
::  returns ( Registry Info about existing typeHandlers  in  HKEY_CLASSES_ROOT ; HKEY_CURRENT_USER )
::     HKCR_HANDLER / HKCR_AUTOFILE / HKCR_DOTEXT ; HKCU_AUTOFILE / HKCU_DOTEXT
::
::-----------------------------------------------------------------------------------------------

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
set HKCU_FileExt_REG="_4_%filetype%_ext.bak"

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
:: ---------------------  Scite registry file Section ---------------------------
::
::  Generate a registry Import File containing new File Type associations
::
::  takes
::    SCITE_INTERACT
::    HKCR_AUTOFILE / HKCR_HANDLER ; HKCU_AUTOFILE / HKCU_DOTEXT
::
:: -----------------------------------------------------------------------------

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
echo ; ----------- %filetype% / %mimetype% ------------ >> %RegFileName%

::----------------------------------------HKCU\......\Explorer\FileExts-------------------------------------
:: "new" Method, write a .filetype and a handler to the key above
:: and list them in MRUList so Users could switch between handlers. 
::
:: 1:) we already have a filetype in HKCU\...\Explorer\FileExts 
::------------------------------------------------------------------------------------------------------------------

IF [%HKCU_DOTEXT%]==[%TRUE%] ( 
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%] >> %RegFileName%
 :: --- Marker
 echo "myScite_change"="" >> %RegFileName%
 :: ---- Handler Name (eg: ext_auto_file)
 echo @="%autofile%">> %RegFileName%
 :: ---- Mime type
 echo "Content Type"="%mimetype%" >> %RegFileName%
 echo "PerceivedType"="text" >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithList] >> %RegFileName%
) 
 
REM --  Note: that classID simply points to %systemroot%\system32
IF [%HKCU_DOTEXT%]==[%TRUE%] (
 echo "a"="{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\OpenWith.exe" >> %RegFileName%
 echo "MRUList"="as" >> %RegFileName%
 echo "s"="SciTE.exe" >> %RegFileName%
 )
 
IF [%HKCU_DOTEXT%]==[%TRUE%] ( 
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\UserChoice] >> %RegFileName%
 echo "Progid"="%progid%" >> %RegFileName%
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo "Applications\\Scite.exe"=hex(0^): >> %RegFileName%
 ) 
 
:: -----------------------------------------------------------------------------------------
:: 2:) we have no extension entry, only a handler for the filetype.  ("oldFashion" style)   
::------------------------------------------------------------------------------------------

IF [%HKCU_DOTEXT%]==[%false%] IF [%HKCU_AUTOFILE%]==[%TRUE%] (
 REM Remove the Key to take care for the case, that it contains a write protected Hash.   
 echo [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%] >> %RegFileName%
 :: --- Marker
 echo "myScite_new"="" >> %RegFileName%
 :: ---- Handler Name (eg: ext_auto_file)
 echo @="%autofile%">> %RegFileName%
 :: ---- Mime type
 echo "Content Type"="%mimetype%" >> %RegFileName%
 echo "PerceivedType"="text" >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithList] >> %RegFileName%
 )
  
IF [%HKCU_DOTEXT%]==[%false%] IF [%HKCU_AUTOFILE%]==[%TRUE%] (
 echo "a"="{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\OpenWith.exe" >> %RegFileName%
 echo "MRUList"="sa" >> %RegFileName%
 echo "s"="SciTE.exe" >> %RegFileName%
 )
 
IF [%HKCU_DOTEXT%]==[%false%] IF [%HKCU_AUTOFILE%]==[%TRUE%] ( 
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\UserChoice] >> %RegFileName%
 echo "Progid"="Applications\\Scite.exe" >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.%filetype%\OpenWithProgids]>>%RegFileName%
 echo "%autofile%"=hex(0^): >> %RegFileName%
 )

::---------------------------------------HKCU\Software\Classes----------------------------------
:: 3:) we have no handler, lets create one.
::-------------------------------------------------------------------------------------------------------
 SET SYS_FILE=1  
 IF [%HKCU_AUTOFILE%]==[%false%] SET autofile=%progid%
 IF [%filetype%] NEQ [cmd] IF [%filetype%] NEQ [bat] IF [%filetype%] NEQ [reg] IF [%filetype%] NEQ [inf] IF [%filetype%] NEQ [CMD] IF [%filetype%] NEQ [BAT] IF [%filetype%] NEQ [REG] IF [%filetype%] NEQ [INF] SET SYS_FILE=0
 
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%] >> %RegFileName%
 echo @=Scite .%filetype% Handler >> %RegFileName%
 
 IF %SYS_FILE%==1 IF [%FIX_REACTOS%]==[0] (
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell] >> %RegFileName%
 echo [-HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\edit]  >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\edit] >> %RegFileName%
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\shell\edit\command] >> %RegFileName%
  echo @=%scite_cmd%>>%RegFileName%
 )
 
:: ---  ICON
 echo [HKEY_CURRENT_USER\Software\Classes\%autofile%\DefaultIcon] >> %RegFileName%
 echo @=%file_icon% >> %RegFileName%
  
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

 REM WorkAround Reactos 0.4.2 Bug.
 ::VER|FIND "ReactOS"
 IF [%FIX_REACTOS%]==[1] ( 
 set scite_cmd="\"%scite_path%\\%cmd%\" %%1"
 )
 
:CLEANUP_SECTION
 :: ---------------- Clean UP and Fin.--------------------------
 del /Q  *.tmp 2>NUL 
 del /Q  *.bak 2>NUL 
 del /Q  *.raw 2>NUL 
 
IF [%SCITE_INTERACT%]==[%TRUE%] echo   ==Temporary storing Files to  ... "%tmp%\scite_tmp"==

cd /D %scite_path%\installer\steampunk

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
echo :::::..::::.:::.::::.:::.::::::.::.. Usage ..:::::.::::::.::::.:::::::..:::::.::::::.:::
echo.                
echo   - able to register new filetypes inclusive its Icon.
echo   - able to associate already registered filetypes with SciTE
echo   - Creates a human readable registry import file
echo   - which can be be imported manually -
echo.
echo  * Syntax: Scite.createExt [.FileExt] [optional MimeTyp]
echo.
echo            *  Example  *
echo   scite.createExt .me
echo   scite.createExt .myfancy text/plain
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
echo :::::..::::.:::.::::.:::.::::::.::.. Usage ..:::::.::::::.::::.:::::::..:::::.::::::.:::
:END
