@echo off 
:: -------- Containery for SciTE ----------
:: can be used to avoid Chaos. Provides version specifc Language Distbins within respective Directories. 
:: ---------------------------------------

set toolFolder=ctags
set toolName=%toolFolder%
set toolExt=.exe
set toolParam=%*

:: A value of 1 will force the wrapper to restrict PATH for toolName (useful for eg tdm/mingw buidChains) 
set sandbox=0

:: -------- No need to edit below here ---------- ::

:: ~dp0 = Full Path to current Directory with trailing slash
set toolPath=%~dp0%toolFolder%

:: temporarly prefix local Path with toolPath 
set path=%toolPath%;%path%;
if [%sandbox%]==[1] ( set path=%toolPath%;%~dp0%)
if [%sandbox%]==[1] ( set mode=[Sandboxed]) else ( set mode= )

:: first try if a user had installed a local package
if exist %toolPath%\%toolName%%toolExt% (
echo ~ wrapper ~ %mode% %toolFolder%\%toolName%%toolExt% %toolParam% >&2
%toolPath%\%toolName%%toolExt% %toolParam%
goto :freude
) 

if [%sandbox%]==[1] goto :err
:: not in restricted Mode ; ok to look for %toolName% within the system 
where /Q %toolName%%toolExt%

IF %ERRORLEVEL% == 0 (
REM echo ~ WRapper: %toolPath%\%toolName%%toolExt% %toolParam% >&2
where %toolName%%toolExt%
%toolName%%toolExt% %toolParam%
goto :freude ) else (  goto :err )

:err
echo ... please install %toolName% or copy a custom pack to 
echo ... %toolPath%

:freude