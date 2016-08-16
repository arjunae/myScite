@echo off
::mode 112,20
REM ---------------- 
REM
REM  Add Scite to Explorer "open with" Context Menu
REM  -Creates Regfile-.
REM
REM  *Outputfile has to be imported manally.*
REM
REM 
REM :: Created Jul 2016, Marcedo@HabmalneFrage.de
REM :: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
REM
REM
REM Search for %cmd% in actual and up to 2 parent Directories
REM Use full qualified path. 
REM
REM ----------------

:main
 set cmd=SciTE.exe
 set scite_cmd=default

 REM ------- this batch can reside in a subdir to support a more clean directory structure
 REM ------- write path of %cmd% in scite_cmd
  
 :: ------- Check for and write path of %cmd% in scite_cmd
 IF EXIST %cmd% (  set scite_cmd="%cmd%"  ) 
 IF EXIST ..\%cmd% (  set scite_cmd="..\%cmd%"  ) 
 IF EXIST ..\..\%cmd% ( set scite_cmd="..\..\%cmd%") 
 
 IF NOT EXIST %scite_cmd% (call :sub_fail) else (call :sub_continue ) 
 
 :: Clean up...
 move %regfile% %userprofile%\desktop >NUL
 del /Q %tmp%\scite.tmp >NUL

 echo. .... copied to %userprofile%\desktop
 echo Now, please press your favorite key to be Done. HanD! 
 goto :freude
 
:sub_continue

 REM ------- Search for %scite_cmd%, expand its path to file scite.tmp
 FOR /D  %%I IN (%scite_cmd%) do echo %%~fI > %tmp%\scite.tmp
 set /P scite_path=<%tmp%\scite.tmp

 REM -- Got that shorthand strReplace from
 REM -- http://www.dostips.com/DtTipsStringOperations.php
 REM -- Remove  \ %cmd%  from scite_path and extend systems PATH
 set str=%scite_path%
 call set str=%str:\scite.exe =%
 set scite_path=%str%

 :: -- replace string \ with \\ 
 set word=\\
 set str=%scite_path%
 CALL set str=%%str:\=%word%%%
 set scite_path=%str%

 :: -- replace string \\ with \\\\ to properly escape two backslashes for Scites -CWD comand"  
 set word=\\\\
 set str=%scite_path%
 CALL set str=%%str:\\=%word%%%
 set scite_path_ext=%str%
 :: echo %scite_path_ext%

 set RegFile=%tmp%\add.scite.to.context.menu.reg
 set scite_cmd="\"%scite_path%\\%cmd%\" \"%%1\" \"-CWD:%scite_path_ext%\""

 REM ---- Finally, write the .reg file, \" escapes double quotes
 echo Windows Registry Editor Version 5.00 > %RegFile%
 echo [-HKEY_CLASSES_ROOT\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CLASSES_ROOT\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CLASSES_ROOT\*\shell\Open with SciTE\command] >> %RegFile%
 echo @=%scite_cmd% >> %RegFile%
 :: echo @="E:\\projects\\.scite.gitSourceForge\\SciTE_webdev\\SciTE.exe %%1" >> %RegFile%
 
 :: ----  Note down how to call scite exe from anywhere on the system. 
 :: echo. > _scite.read.me.path.txt
 :: echo "Hint: Use this parameters to open scite from anywhere:" >> _scite.read.me.path.txt
 :: echo %scite_path% "%%1" "-cwd:%scite_path_ext%" >> _scite.read.me.path.txt

 echo ..... Finished writing to  %RegFile% ....
 
 exit /b
:end_sub

:sub_fail
 echo.
 echo Please fix: %cmd% was'nt found or Filename did'nt match variable "cmd"
 echo ...Try to copy this file to scites root dir...
 echo ...any key...
 pause >NUL
exit
:end_sub
:freude
:: wait some time...
ping 1.0.3.0 /n 1 /w 3000 >NUL