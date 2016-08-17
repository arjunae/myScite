@echo off 
:: Permanently append the current Path to the Users PATH Environment.
:: Dont touch Systems global Path, so prior installed Dists keep precedence.
echo.
echo ::...:: Register Helpers ::...:: 
echo. 
setlocal enabledelayedexpansion enableextensions
set contrib_path=%~dp0

:: Query Users current Path 
for /F "tokens=1,2* delims= " %%a in ('reg query HKCU\Environment /v Path') do (
Set cur_path=%%c
)

echo ------------------- Current Path -------------------------.
echo.
:: Check if path was already appended
set str=%cur_path%
set delim=;
call :searchPath
echo.
echo -------------------- Result ------------------------------.
echo.
if "%check_path%" equ "yo" (
echo	Path found ... no need to append... 
goto :freude 
)
::set cur_path=%str%

:: Okay, continue
reg add HKCU\Environment /f /v Path /t REG_EXPAND_SZ /d "%cur_path%;%contrib_path%;%contrib_path%;" >NUL

:: setx (available >= winSrv2003) - a "touchy" MS Eqivalent to above Code.   
set cur_path=%cur_path%;%contrib_path%
setx PATH %cur_path% 2>NUL 1>NUL
  
echo  .... %contrib_path%
echo  ....  has been appended to your Path :)
goto :freude

:searchPath
set ^"str=!str:%delim%=^

!"
for /f "eol=; delims=" %%X in ("!str!") do (
	if "%%X"=="%contrib_path%" ( 
		set check_path=yo
		echo ~ Match ...  %%X
	)	else ( echo ~ %%X )
)

set check_path =%check_path%
exit /b

:: Reputation for this nice job flows to http://stackoverflow.com/users/1012053/dbenham
:end_sub

:freude
ENDLOCAL
echo.
echo --------------------- Fin --------------------------------.
echo waiting some time... (10sek)
ping 11.01.19.77 /n 1 /w 8000 >NUL


