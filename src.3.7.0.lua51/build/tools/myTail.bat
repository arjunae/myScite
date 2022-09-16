@echo off

REM :::===---
REM Watch for inFile's Updates and print newly added Lines
REM -> a poor Mens Tail in pure batch.
REM
REM Marcedo@habMalNeFrage.de
REM https://github.com/arjunae/youtube_playlist_localhost/tree/master/stream_tools
REM Lic: BSD3Clause
REM :::===---

setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

set FileName=%1
REM set FileName="new.txt"
SET lineCount=0
SET trigger=0
IF NOT EXIST %FileName% EXIT

:: store inital Files size in bytes
echo Watchin %FileName% for new lines
FOR %%A IN (%FileName%) DO SET FileSize=%%~zA
set oldFileSize=%FileSize%

REM Now check for File Updates once per second.
:loop
	timeout /T 1 1>NUL
	FOR %%A IN (%FileName%) DO SET FileSize=%%~zA
	IF %oldFileSize% NEQ %FileSize% (
		::echo ..file update...
		set LineCount=0
		call :readFile
		set oldFileSize=%FileSize%
		)
goto :loop

REM Iterate through and print newly added Lines.
REM based on Code by https://superuser.com/users/337631/davidpostill
:readFile
	FOR /f  "usebackq tokens=*" %%b IN (`type %FileName%`) DO (
		set LineString=%%b
		call :output
	)
	exit /b 0
:done

:output
	set /a LineCount+=1
	IF %LineCount% GTR %trigger% (
		echo %LineString%
		set trigger=%LineCount% 
		)
	exit /b 0
:done
