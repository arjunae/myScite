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

-- External Keywords
lex:add_rule('extCMD', token(lexer.FUNCTION, word_match([[
  assoc color cscript arp at atmadm attrib bootcfgcacls chcp chkdsk chkntfs cipher
  cmd cmstp comp compact convert cprofile defrag diskcomp diskcopy diskpart doskey
  driverquery eventcreate eventquery eventtriggersexpand fc find findstr format
  fsutil ftp getmac gpresult gpupdate graftabl help ipconfig ipxroute label lodctr
  logman lpq lpr mode moremd move mountvolmsiexec nbtstat netsh netstatntbackup
  openfiles pathping pause ping print rasdial rcp recover reg regsvr32 relog replace
  rexec robocopy route runas sc schtasks shutdown sort subst systeminfo sfc taskkill
  tasklist telnet tftp tracerpt tracert tree typeperf unlodctr verify vol vssadmin
  w32tm xcopy append debug edit edlin exe2bin fastopen forcedos graphics loadfix
  mem nlsfunc setver share start choice loadhigh lh prompt wscript
]], true)))

-- Predefined Env.
lex:add_rule('constants', token(lexer.CONSTANT, '%' * word_match([[
  allusersprofile appdata clientname cmdcmdline cmdextversion comspec 
  commonprogramfiles computername errorlevel homedrive homepath
  localappdatalogonserver number_of_processors os path pathext
  processor_architecture processor_identifier processor_level processor_revision
  programfiles random sessionname systemdrive systemroottemp tmp userdnsdomain 
  userdomain username userprofile windir
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
