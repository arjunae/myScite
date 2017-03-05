@echo off
mode 112,20
REM ---------------- Test Batch -----------------
REM creates a reg file which you can use to add Scite to explorers context Menu
REM -----------------------------------------------

echo  ... Click outputPane and press Key.
echo ... List all Files, starting from current Directory...
pause >NUL
call :sub_lister
echo  ... Listed all Files, started from current Directory...

:main
 set cmd=SciTE.exe
 set scite_cmd=default

 REM ------- this batch can reside in a subdir to support a more clean directory structure
 REM ------- write path of %cmd% in scite_cmd

 :: ------- Check for and write path of %cmd% in scite_cmd
 pushd
 IF EXIST %cmd% ( set scite_cmd="%cmd%" )
 IF EXIST ..\%cmd% ( set scite_cmd="..\%cmd%" )
 IF EXIST ..\..\%cmd% ( set scite_cmd="..\..\%cmd%")
 IF NOT EXIST %scite_cmd% ( call :sub_fail) else ( call :sub_continue )

 :: Clean up...
 move %regfile% %userprofile%\desktop >NUL
 del /Q %tmp%\scite.tmp >NUL
 popd
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
 echo ; -- Update ShellMenu Entry >> %RegFile%
 echo [-HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\Open with SciTE\command] >> %RegFile% 
 echo @=%scite_cmd% >> %RegFile%
 
 :: echo @="E:\\projects\\.scite.gitSourceForge\\SciTE_webdev\\SciTE.exe %%*" >> %RegFile%

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

:sub_lister
:: List all Files, begin from current DIR
:: Press F5 to test.

setlocal EnableDelayedExpansion

FOR /R %%I IN (*.*) DO (
  echo -- %%I
)

::runas /noprofile /user:Tho cmd
exit /b
:end_sub

:freude
:: wait some time...
ping 1.0.3.0 /n 1 /w 5000 >NUL
