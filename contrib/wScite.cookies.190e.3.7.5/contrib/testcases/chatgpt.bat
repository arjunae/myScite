@echo off
setlocal enabledelayedexpansion

REM chatgpt DOS with curl. 
REM 24.04.25 by thorstenK arjunae@nurfuerspam.de
REM limitations: parses for content: string within the answer
REM free code

set "API_KEY="
set /p PROMPT=Bitte gib deine Frage an ChatGPT ein: 
set "TMPFILE=response.json"
del "%TMPFILE%" >nul 2>&1
curl -s https://api.openai.com/v1/chat/completions ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %API_KEY%" ^
  -d "{\"model\": \"gpt-3.5-turbo\",\"messages\": [{\"role\": \"user\", \"content\": \"%PROMPT%\"}],\"temperature\": 0.7}" > "%TMPFILE%"

echo.
echo Antwort von ChatGPT:
echo --------------------------------------

REM Multiline json antworten parsen. sucht "content":
REM sollte selten vorkommen das der string "content:" in chatgpt dialogen vorkommt
set "capture=0"

for /f "usebackq delims=" %%A in ("%TMPFILE%") do (
    set "line=%%A"
    echo !line! | findstr /c:"\"content\":" >nul
    if !errorlevel! == 0 (
        set "capture=1"
        :: erste Zeile abtrennen
        set "line=!line:*\"content\": =!"
        set "line=!line:\"=!"
        echo !line!
    ) else (
        if !capture! == 1 (
            set "cleanline=!line:\"=!"
            echo !cleanline!
            echo !cleanline! | findstr /r "^[ \t]*[]}]$" >nul
            if !errorlevel! == 0 (
                set "capture=0"
            )
        )
    )
)

echo --------------------------------------
del "%TMPFILE%" >nul 2>&1
endlocal
pause
