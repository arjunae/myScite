-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Batch LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('batch', {case_insensitive_fold_points = true})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Internal Keywords.
lex:add_rule('intCMD', token(lexer.KEYWORD, word_match([[
  break cd chdir date time md mkdir cls for if echo echo. move copy rd ren rename rmdir 
  del dir erase ftype set call exit ver type title setlocal shift endlocal pause 
  defined exist errorlevel else in do NUL AUX CON PRN not goto pushd popd 
  eol equ geqgtrleq neqskip tokens usebakq delims @ on off
]], true)))

-- External Keywords https://www.lifewire.com/list-of-command-prompt-commands-4092302
lex:add_rule('extCMD', token(lexer.FUNCTION, word_match([[
command append arp assoc at atmadm attrib auditpol bcdboot bcdedit bdehdcfg bitsadmin bootcfg bootsect break
cacls call cd certreq certutil change chcp chdir checknetisolation chglogon chgport chgusr chkdsk chkntfs choice
cipher clip cls cmd cmdkey cmstp color command comp compact convert copy cscript ctty date dblspace debug
defrag del deltree diantz dir diskcomp diskcopy diskpart diskperf diskraid dism dispdiag djoin doskey dosshell
dosx driverquery drvspace echo edit edlin emm386 endlocal erase esentutl eventcreate eventtriggers exe2bin exit
expand extrac32 extract fasthelp fastopen fc fdisk find findstr finger fltmc fondue for forcedos forfiles format
fsutil ftp ftype getmac goto gpresult gpupdate graftabl graphics help hostname hwrcomp hwrreg icacls ift
interlnk intersvr ipconfig ipxroute irftp iscsicli kb16 keyb klist ksetup ktmutil label lh licensingdiag loadfix
loadhigh lock lodctr logman logoff lpq lpr makecab manage-bde md mem memmaker mkdir mklink mode
mofcomp more mount mountvol move mrinfo msav msbackup mscdex msd msg msiexec muiunattend nbtstat
net net1 netcfg netsh netstat nfsadmin nlsfunc nltest nslookup ntbackup ntsd ocsetup openfiles path
pathping pause pentnt ping pkgmgr pnpunattend pnputil popd power powercfg print prompt pushd pwlauncher
qappsrv qbasic qprocess query quser qwinsta rasautou rasdial rcp rd rdpsign reagentc recimg recover
reg regini register-cimprovide regsvr32 relog ren rename repair-bde replace reset restore rexec
rmdir robocopy route rpcinfo rpcping rsh rsm runas rwinsta sc scandisk scanreg schtasks sdbinst secedit
set setlocal setspn setver setx sfc shadow share shift showmount shutdown smartdrv sort start subst sxstrace
sys systeminfo takeown taskkill tasklist tcmsetup telnet tftp time timeout title tlntadmn tpmvscmgr tracerpt
tracert tree tscon tsdiscon tskill tsshutdn type typeperf tzutil umount undelete unformat unlock unlodctr vaultcmd
ver verify vol vsafe vssadmin w32tm waitfor wbadmin wecutil wevtutil where whoami winmgmt winrm winrs winsat
wmic wscript wsmanhttpconfig xcopy xwizard
]], true)))

-- Predefined Env. Source: windows10 1803
lex:add_rule('constants', token(lexer.CONSTANT, '%' * word_match([[
allusersprofile appdata clientname cmdcmdline cmdextversion commonprogramfiles commonprogramfiles(x86)
commonprogramw6432 computername comspec errorlevel homedrive homepath localappdata logonserver number_of_processors
os path pathext processor_architecture processor_identifier processor_level processor_revision programdata
programfiles programfiles(x86) programw6432 prompt psmodulepath public sessionname systemdrive systemroot
temp tmp userdnsdomain userdomain userdomain_roamingprofile username userprofile windir 
]], true)*'%'))

-- Comments.
local rem = (P('REM') + 'rem') * lexer.space
lex:add_rule('comment', token(lexer.COMMENT, (rem + '::') * lexer.nonnewline^0))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range('"', true)))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE,
                               '%' * (lexer.digit + '%' * lexer.alpha) +
                               lexer.delimited_range('%', true, true)))

-- Labels.
lex:add_rule('label', token(lexer.LABEL, ':' * lexer.word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-|&!<>=()')))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'setlocal', 'endlocal')
lex:add_fold_point(lexer.OPERATOR, '(', ')')

return lex
