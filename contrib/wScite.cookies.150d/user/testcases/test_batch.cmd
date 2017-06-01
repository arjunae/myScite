@echo off
mode 112,20
REM ---------------- Test Batch -----------------
REM creates a reg file which you can use to add Scite to explorers context Menu
REM -----------------------------------------------

echo  ... Click outputPane and press Key.
echo ... List all Files, starting from current Directory...
pause >NUL
call :sub_lister
echo  ... Listed all Files, started from current Directory...
call :freude

:sub_lister
:: List all Files, begin from current DIR
:: Press F5 to test.

setlocal EnableDelayedExpansion

FOR /R %%I IN (*.*) DO (
  echo -- %%I
)

::runas /noprofile /user:Tho cmd
exit /b
:end_sub

:freude
:: wait some time...
ping 1.0.3.0 /n 1 /w 2000 >NUL
