@echo off
chcp 65001 1>NUL
setlocal enabledelayedexpansion enableextensions

::  ---- Wrapper for scite_filetypes.vbs install ----
::
:: Export property "file.patterns" from all property files
:: Registers all SciTE known Filetypes.
:: Setting Param1 to /quite skips User Prompts.
::
:: Mar2018 - Marcedo@habMalNeFrage.de ; License: BSD-3-Clause
:: Apr2018 - Support ReadOnly Spaces.
::

set DataFile=scite_filetypes.txt
set file_name=scite.exe
set scite_dir=empty
pushd %~dp0%
IF EXIST %DataFile% (SET Have_Data=true)

:: Find and Store Root Dir for later.

:loop
  set /a dir_count += 1
  if %dir_count% geq 10 (goto end_loop) else (cd ..)
   if exist "%file_name%" (
    set scite_dir="%cd%"
    set scite_userdir="%cd\user%"
    set scite_bin="%cd%\%file_name%"
    goto end_loop
    )	
  goto loop 
:end_loop
IF NOT EXIST %scite_dir% ( 
 echo ... Can't find Scite's Root Dir. Stop.
 goto DataFileErr 
) 

:: Skip User Questions with Param /quite
if ["%1"] equ ["/quite"] ( set arg1=install && goto CREATE_FILE )
echo   ..About to soft-register Filetypes with mySciTE
call choice /C YN /M " Continue?  Yes/No" 
if %ERRORLEVEL% == 2 goto ende

:CREATE_FILE
 REM Only Recreate the File when we have a Data folder and rw space.
 echo test>test.tmp2>NUL && IF EXIST test.tmp (del test.tmp && SET fs_read_write=1)
 IF EXIST %scite_userDir% and if %fs_read_write% (
  :: Stupid "del" does not change ErrorLevel when the deletion failed. Working around... 
  if exist scite_filetypes?.txt (del /F /Q scite_filetypes?.txt 1>NUL 2>NUL)
  if exist scite_filetypes?.txt (
   echo ... Found an System locked %DataFile% please reboot or remove manually.
   goto DataFileErr
  )
 )

if [%Have_Data%] equ [true] (popd && goto MAIN)
 echo  .. Creating %DataFile%
 :: collect file.patterns from all properties, ( prefixed with properties filename)
 FINDSTR /SI "^file.patterns." *.properties > filetypes1.raw

 :: Now filter unusable dupe entries (variable references) from above tmpfile. 
 FINDSTR /SIV "$(" filetypes1.raw > filetypes2.raw

 :: Finally, strip the file names, but keep the fileexts information. 
 for /F "delims=: eol=# tokens=3" %%E in (filetypes2.raw) do (
  echo %%E>>%DataFile%
  if ["%1"] neq ["/quite"] echo %%E
 ) 

 :: Clean Up
 del *.raw?
 popd
 move %scite_root%\%DataFile% .
:END_CREATE_FILE

:MAIN
 echo  .. Parsing Filetypes in %DataFile% ..
 cscript /NOLOGO scite_filetypes.vbs %arg1% %scite_bin%
 IF %ERRORLEVEL% equ 0 goto :DataFileErr
 IF %ERRORLEVEL% geq 900 goto :DataFileErr
 echo  .. done with %ERRORLEVEL% Entries ..
 echo.
 popd
 goto ende
:END_MAIN

:DataFileErr
 pause
 exit(969)
:END_DataFileErr

:ende
if ["%1"] neq ["/quite"] Pause