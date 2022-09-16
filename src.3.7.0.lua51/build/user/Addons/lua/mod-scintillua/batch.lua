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
  break call cd chdir date time md mkdir cls for if echo echo. move copy rd ren rename rmdir 
  del dir erase ftype set exit ver type title setlocal shift endlocal pause pushd popd
  defined delims exist errorlevel else in do NUL AUX CON PRN not goto eol equ neq geq gtr leq lss
  neq skip tokens usebakq verify delims @ on off
]], true)))

-- External Keywords 
-- XP: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-xp/bb490890(v=technet.10)
-- WinServer/Win10: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands
lex:add_rule('extCMD', token(lexer.FUNCTION, word_match([[
arp assoc at atmadm attrib batchfiles bootcfg cacls change chcp chkdsk chkntfs cipher cmd cmstp
color comp compact convert copy cprofile cscript date defrag del dir diskcomp diskcopy diskpart doskey driverquery
eventcreate eventquery eventtriggers evntcmd exit expand fc find findstr finger flattemp for format
fsutil ftp ftype getmac gpresult gpupdate graftabl help helpctr hostname ipconfig ipseccmd ipxroute irftp label
lodctr logman lpq lpr macfile mmc mode more mountvol move msiexec msinfo32 nbtstat net netsh netstat nslookup ntbackup
ntcmdprompt ntsd openfiles pagefileconfig path pathping pbadmin pentnt perfmon ping print prncnfg prndrvr
prnjobs prnmngr prnport prnqctl prompt query rasdial rcp recover redirectionoperators reg regsvr32 relog
replace resetsession rexec route rsh rsm runas sc schtasks secedit shift shutdown sort start subst
systeminfo sfc taskkill tasklist tcmsetup telnet tftp time title tracerpt tracert tree type typeperf unlodctr
vol vssadmin w32tm winnt32 wmic xcopy 
append auditpol autochk autoconv autofmtbcdboot bcdedit bdehdcfg bitsadminbootcfg breakcacls certreq certutil chglogon chgport
chgusr choice clip cmdkey cscriptdate dcgpofix dfsrmig diantz diskperf diskraid diskshadow dispdiag dnscmd driverqueryecho edit
extract fondue forfiles freedisk fveupdategetmac gettype gpfixup icacls inuse irftpjetpack klist ksetup ktmutil ktpass logoff makecab
manage-bde mapadmin mklink mount mqbkup mqsvc mqtgsvc msdt msg mstsc netcfg netprint nfsadmin nfsshare nfsstat nlbmgr
nsysocmgr ntfrsutl pnpunattend pnputil powershell powershell_ise pubprn pushprinterconnections qappsrv qprocess quser qwinsta
rdpsign regini rem repair-bde risetup robocopy route_ws2008 rpcinfo rpcping rundll32 rwinsta scwcmd serverceipoptin servermanagercmd
serverweroptin setx shadow showmount sxstrace takeown tapicfg timeout tlntadmn tpmvscmgr tscon tsdiscon tsecimp tskill tsprof tzutil
unlodctrver verifier vssadmin- waitfor wbadmin wdsutil wecutil wevtutil where whoami winnt winpop winrs wlbs wscript 
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
