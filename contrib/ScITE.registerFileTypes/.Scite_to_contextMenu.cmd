@echo off
::mode 112,20

REM  ::--::--::--::--Steampunk--::-::--::--::
REM
REM  Add Scite to Explorer "open with" Context Menu
REM  -Creates a regfile which has to be imported manally.-
REM
REM :: Created Jul 2016, Marcedo@HabmalneFrage.de
REM :: URL: https://sourceforge.net/projects/scite-webdev/?source=directory
REM
REM - Aug16 - Search for %cmd% in actual and up to 2 parent Directories / Use full qualified path. 
REM - Okto16 - create / reset Program Entry RegistryKey  
REM - Nov16 - reactos fix / check admin
REM
REM ::--::--::--::--Steampunk--::-::--::--::

 pushd %~dp0%
 
:check_user
 SET ADMIN=NIL
 net session >nul 2>&1
 if [%ERRORLEVEL%]==[0] SET ADMIN=1 
 popd

:main
 REM WorkAround Reactos 0.4.2 Variable Expansion Bug.
 ::set FIX_REACTOS=1

 set cmd=SciTE.exe
 set scite_cmd=default

 REM ------- this batch can reside in a subdir to support a more clean directory structure
 
 :: ------- Check for and write path of %cmd% in scite_cmd
 IF EXIST %cmd% (  set scite_cmd="%cmd%"  ) 
 IF EXIST ..\%cmd% (  set scite_cmd="..\%cmd%"  ) 
 IF EXIST ..\..\%cmd% ( set scite_cmd="..\..\%cmd%") 
 
 IF NOT EXIST %scite_cmd% (call :sub_fail) else (call :sub_continue ) 
 
 :: Clean up...
 move /Y "%regfile%" "%userprofile%\desktop">NUL
 del /Q %tmp%\scite.tmp >NUL

 echo. .... copied to %userprofile%\desktop

 echo   -------------------------------------------
 echo.
 echo   Work Done - I hope you had a nice time !
 echo   Please press your favorite key to be Done. 
 echo.  :) Greetings to you from Deutschland, Darmstadt :) 
 echo.

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
 
 echo Windows Registry Editor Version 5.00 > %RegFile%
 
 IF %ADMIN%==1 ( 
 REM ---- Finally, write the .reg file, \" escapes double quotes
 echo [-HKEY_CLASSES_ROOT\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CLASSES_ROOT\*\shell\Open with SciTE] >> %RegFile%
 echo [HKEY_CLASSES_ROOT\*\shell\Open with SciTE\command] >> %RegFile%
 echo @=%scite_cmd% >> %RegFile%
)

 REM WorkAround Reactos 0.4.2 Bug.
 IF [%FIX_REACTOS%]==[1] ( 
 set scite_cmd="\"%scite_path%\\%cmd%\" %%1"
 )
 
 :: create / reset Program Entry RegistryKey (..in HKEYCurrenUser..)
 echo [-HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell\open] >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\shell\open\command] >> %RegFile%
 echo @=%scite_cmd% >> %RegFile%
 echo [HKEY_CURRENT_USER\SOFTWARE\Classes\Applications\scite.exe\SupportedTypes] >> %RegFile%
 echo ".*"="">> %RegFile%

 :: echo ..... Finished writing to  %RegFile% ....
 copy "%RegFile%" scite.filetypes.register.reg>NUL
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
::ping 1.0.3.0 /n 1 /w 3000 >NUL
pause >NUL
