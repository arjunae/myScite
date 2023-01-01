@echo off
REM Status: beta  (not final) Free Software (FreeBsd 3Clause)
REM Thorsten Kani/ arjunae@schmusemail.de A simple Tail in pure batch. 
REM Update: In an Interview it said "Im more patient and conscientious while following your files now. And i dont use Lockfiles for signalling  :) "
REM Tested with usual control operators and line bulks up to 10 Lines at once in the pipe.
REM 

setlocal enabledelayedexpansion enableextensions
REM Init Behaviour: Set to 0 to only print newly added lines 
set /a LinesBefore=501

REM Iterate through and print newly added Lines.
set LineBufferCnt=0
set LineBufferArray=a
set /a prevFileLineCnt=0 
rem set filename="%tmp%\scitelog.txt"
if "%1" equ "-h" goto usage
if "%1"==""  (set /p filename="File to follow? ")  else (set Filename=%1)
IF not EXIST %FileName% (echo No, because i can't find File %FileName%) & goto de
REM Check if theres and add a marker needle on the board, so other programs know its running.
REG query HKCU\Console\ /v tailRuns 1>Nul 2>Nul
if "%errorlevel%" equ "0" choice /c yn /m "Tail already seems to run. Continue ?"
if "%errorlevel%" equ "2" (set errorlevel=1 & goto de) else (REG add HKCU\Console\ /v tailRuns /t REG_BINARY /d 00000001 /f)

:loop
REM for /F "tokens=2 delims=:" %n in ('find /V /C "" "%filename%"') do Set /a FileLines=%n
REM store newly added Lines in the array and print them 
set /a FileLineCnt=0
FOR /f "tokens=*" %%b IN ('type %filename%') DO (
	set /a FileLineCnt+=1
	if "%%b" neq "" set /a LineBufferCnt+=1 & set LineBufferArray!LineBufferCnt!=%%b
	if !FileLineCnt! equ !prevFileLineCnt! (set /a skipLines=!LineBufferCnt!+1)
)
if !FileLineCnt! gtr !prevFileLineCnt! (
	set /a newLines =!FileLineCnt!-!prevFileLineCnt! 
REM 	echo Debug: Recieved !newLines! new lines
	REM initially print preexisting lines up to the length of the lineBuffer
	if !LinesBefore! gtr !LineBufferCnt! set /a LinesBefore=!LineBufferCnt!
	if !LinesBefore! gtr 0 set /a LinesBefore=!LineBufferCnt!-!LinesBefore!+1 & set /a skipLines=!LinesBefore!
	for /L %%a in (!skipLines!,1,!LineBufferCnt!) do (echo !LineBufferArray%%a!)
	set LinesBefore=0
	set prevFileLineCnt=!FileLineCnt!
) else goto wait

:wait
set prevFileLineCnt=!FileLineCnt!
set LineBufferCnt=1
REM play with yourself for some time and return later.
rem for /l %%w in (1,1,2000) do (echo.>nul)
REM Wait RTT time pinging localhost 
ping -n 1 localhost > nul
if not exist %tmp%\tail.lck goto :de
goto loop
:usage
echo Usage: tail Filename
:de
REM take off the marker needle from the board and put it back where needles are safe and feel warm and comfortable when unused.
REG delete HKCU\Console\ /v tailRuns /f 1>nul 2>nul

REM play with implementation but dont disturb neighbors :>
for /l %a in (1,1,10) do echo %a >> de.log
