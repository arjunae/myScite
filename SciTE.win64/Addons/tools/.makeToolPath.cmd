@echo off
:: Permanently appends the current directory to the currently logged on Users PATH Environment Variable.
:: Any prior installed Programs keep precedence, even when they dont use the Systemwide Path.
:: - ensures that a Path wont be added again if it was found to be already in.

echo.
echo ::...:: Register Helpers ::...::
echo.
setlocal enabledelayedexpansion enableextensions
set contrib_path=%CD%
:: or %~dp0

:: Query Users current Path
for /F "tokens=1,2* delims= " %%a in ('reg query HKCU\Environment /v Path') do (
Set cur_path=%%c
)

echo Current Path:
echo.
:: Check if path was already appended
set str=%cur_path%
set delim=;
call :searchPath
echo.
echo ------------------- Script Result ----------------------------.
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

:: Optional: apply changes to HKCU on systems which might need a reboot.
::RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True

echo  .... %contrib_path%
echo  ....  has been appended to your localusers Path :)
goto :freude

:searchPath
:: Reputation for this nice snip flows to http://stackoverflow.com/users/1012053/dbenham
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
:end_sub

:freude
ENDLOCAL
echo.
echo ----------------------- Fin ----------------------------------.
::echo waiting some time... (10sek)
::ping 11.01.19.77 /n 1 /w 10000 >NUL
PAUSE

