@echo off
REM Beanshell starter script (AB)
REM $Id: java_api.bat 626 2011-07-11 00:12:15Z andre $
title Beanshell
setlocal
REM To generate java API files for a different Java version, set JAVA_HOME to
REM the directory of an alternate JDK or JRE
REM set JAVA_HOME=C:\j2sdk1.4.2_05
REM If the Beanshell jar file is not in the same directory than the startup
REM script (current file), change the value of the following variable
REM set BSH_HOME=
set JAVA_EXE=java
:BSH_HOME
set BSH_HOME_DEFAULT=%~dp0
if {%BSH_HOME%}=={} (
  (echo BSH_HOME is not set, assuming: %BSH_HOME_DEFAULT%)
  (set BSH_HOME=%BSH_HOME_DEFAULT%)
)
:JAVA_HOME
if {%JAVA_HOME%}=={} (
  (echo JAVA_HOME is not set, using default java available)
  (GOTO CLASSPATH)
)
echo Using JAVA_HOME=%JAVA_HOME%
set JAVA_EXE=%JAVA_HOME%\bin\java
:CLASSPATH
set LOCALCLASSPATH=%BSH_HOME%
for %%i in ("%BSH_HOME%\*.jar") do call :LCP "%%i"
goto MAIN
:LCP
set LOCALCLASSPATH=%LOCALCLASSPATH%;%1
echo CLASSPATH: %LOCALCLASSPATH%
goto :EOF
:MAIN
%JAVA_EXE% -XX:MaxPermSize=128m -cp %LOCALCLASSPATH% bsh.Interpreter SciteJavaApi.bsh
REM %JAVA_EXE% -classpath %LOCALCLASSPATH% bsh.Interpreter
REM %JAVA_EXE% -classpath %LOCALCLASSPATH% bsh.Console
:END
endlocal
title %ComSpec%