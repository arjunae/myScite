@echo off
REM 14.12/2022 Thorsten Kani / arjunae@schmusemail.de A simple Tail in pure batch. 
REM Update: In an Interview it said "Im more patient and conscientious while following your files now.  :) "
REM Tested with usual control operators and line bulks up to 10 Lines at once in the pipe.
REM 
setlocal enabledelayedexpansion enableextensions
REM Init Behaviour: Set to 0 to only print newly added lines 
set /a LinesBefore=14

REM Iterate through and print newly added Lines.
set LineBufferCnt=0
set LineBufferArray=a
set /a prevFileLineCnt=0 
rem set filename="%tmp%\scitelog.txt"
if "%1" equ "-h" goto usage
if "%1"==""  (set /p filename="File to follow? ")  else (set Filename=%1)
IF not EXIST %FileName% (echo No, because i can't find File %FileName%) & goto de
echo.> %tmp%\tail.lck

:loop
REM for /F "tokens=2 delims=:" %n in ('find /V /C "" "%filename%"') do Set /a FileLines=%n
REM store newly added Lines in the array and print them 
set /a FileLineCnt=0
FOR /f "tokens=*" %%b IN ('type %filename%') DO (
	set /a FileLineCnt+=1
	if "%%b" neq "" set /a LineBufferCnt+=1 & set LineBufferArray!LineBufferCnt!=%%b
	if !FileLineCnt! gtr !prevFileLineCnt! (set /a skipLines=!LineBufferCnt! )
)
if !FileLineCnt! gtr !prevFileLineCnt! (
	set /a newLines =!FileLineCnt!-!prevFileLineCnt! 
 	echo Debug: Recieved !newLines! new lines
	REM initially print preexisting lines up to the length of the lineBuffer
	if !LinesBefore! gtr !LineBufferCnt! set /a LinesBefore=!LineBufferCnt!
	if !LinesBefore! gtr 0 set /a LinesBefore=!LineBufferCnt!-!LinesBefore!+1 & set /a skipLines=!LinesBefore!	
	for /L %%a in (!skipLines!,1,%LineBufferCnt%) do (echo !LineBufferArray%%a!)
	set !LinesBefore!=0
	set prevFileLineCnt=!FileLineCnt!
) else goto wait
set LineBufferCnt=1

:wait
REM play with yourself for some time and return later.
for /l %%w in (1,1,2000) do (echo.>nul)
rem ping -n 1 -w 500 localhost > nul
rem if not exist %tmp%\tail.lck goto :de
goto loop
:usage
echo Usage: tail Filename
:de
if exist %tmp%\tail.lck del /q %tmp%\tail.lck

REM play with implementation. try some special Chars
REM echo ^^xx>de.log & echo ^"x>de.log echo ^(xx >de.log
