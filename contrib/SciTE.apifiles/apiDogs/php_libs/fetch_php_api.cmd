@echo off
REM A poor mans php function list fetcher

if exist pecl\php_pecl.txt  cscript.exe simple.vbs  pecl\php_pecl.txt
if exist pecl\php_pecl_ref.txt  cscript.exe parse_refs.vbs  pecl\php_pecl_ref.txt
exit


if exist core\php_core.txt  cscript.exe simple.vbs core\php_core.txt
if exist bundled\php_bundled.txt  cscript.exe simple.vbs  bundled\php_bundled.txt
if exist external\php_external.txt  cscript.exe simple.vbs  external\php_external.txt
if exist pecl\php_pecl.txt  cscript.exe simple.vbs  pecl\php_pecl.txt
if exist utf8.txt del utf8.txt

echo Now fetching functions
pause

if exist core\php_core_ref.txt  cscript.exe parse_refs.vbs core\php_core_ref.txt
if exist bundled\php_bundled_ref.txt  cscript.exe parse_refs.vbs  bundled\php_bundled_ref.txt
if exist external\php_external_ref.txt  cscript.exe parse_refs.vbs  external\php_external_ref.txt
if exist pecl\php_pecl_ref.txt  cscript.exe parse_refs.vbs  pecl\php_pecl_ref.txt

echo OK- Fin
pause


