-- Copyright 2006-2016 Mitchell mitchell.att.foicica.com. See LICENSE.
-- a Batchfile Lexer.

local l = require('lexer')
local token, word_match = l.token, l.word_match
local B, P, R, S = lpeg.B, lpeg.P, lpeg.R, lpeg.S
local M = {_NAME = 'batch'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local rem = (P('REM') + 'rem' + '::' ) * l.nonnewline_esc^0
local comment = token(l.COMMENT, rem)

-- Internal Keywords.
-- ToDo - use SciTEs existing lua State and - M.property() ?
local kw_int = token(l.KEYWORD,  B(l.space) * word_match({
'break', 'cd', 'chdir', 'defined' , 'exit', 'md', 'mkdir', 'cls', 'for', 'if', 'echo', 'echo.', 'eol', 'equ', 'geq','gtr','leq','lss', 'neq', 'move','skip', 'copy', 'ren', 'del', 'set', 'exit', 'setlocal', 'shift', 'tokens', 'usebakq' ,'endlocal', 'pause', 'defined', 'delims', 'exist','errorlevel', 'else', 'in', 'do', 'CON', 'NUL', 'AUX', 'PRN','not', 'pushd', 'popd'
}, nil, true))

-- External Keywords.
local kw_ext = token(l.FUNCTION, B(l.space) * word_match({
'assoc','chdir', 'cls', 'color', 'copy', 'date', 'del', 'dir', 'erase', 'ftype', 'mkdir', 'md', 'move', 'pause', 'rd', 'ren', 'rename', 'rmdir', 'setlocal', 'shift', 'time', 'title', 'type', 'ver', 'verify', 'vol', 'arp', 'at', 'atmadm', 'attrib', 'bootcfg','cacls', 'chcp', 'chkdsk', 'chkntfs', 'cipher', 'cmd', 'cmstp', 'comp', 'compact', 'convert', 'cprofile', 'defrag', 'diskcomp', 'diskcopy', 'diskpart', 'doskey', 'driverquery', 'eventcreate', 'eventquery', 'eventtriggers','expand', 'fc', 'find', 'findstr', 'format', 'fsutil', 'ftp', 'getmac', 'gpresult', 'gpupdate', 'graftabl', 'help', 'ipconfig', 'ipxroute', 'label', 'lodctr', 'logman', 'lpq', 'lpr', 'mode', 'more', 'mountvol', 'msiexec', 'nbtstat', 'netsh', 'netstat','ntbackup', 'openfiles', 'pathping', 'ping', 'print', 'rasdial', 'rcp', 'recover', 'reg', 'regsvr32', 'relog', 'replace', 'rexec', 'robocopy', 'route', 'runas', 'sc', 'schtasks', 'shutdown', 'sort', 'subst', 'systeminfo', 'sfc', 'taskkill', 'tasklist','telnet', 'tftp', 'tracerpt', 'tracert', 'tree', 'typeperf', 'unlodctr', 'vssadmin', 'w32tm', 'xcopy', 'append', 'debug', 'edit', 'edlin', 'exe2bin', 'fastopen', 'forcedos', 'graphics', 'loadfix', 'mem', 'nlsfunc', 'setver', 'share', 'start', 'choice', 'loadhigh', 'lh', 'prompt', 'set', 'errorlevel', "wsript", "cscript"
}, nil, true))

-- Generic External Keywords.
local exts= P(".exe") + P(".com") +P(".nt") + P(".ps") + P(".bat") + P(".vbs") + P(".js")
local my_generics = token(l.TYPE, l.word * exts)

-- Predefined Env.
local kw_env = token(l.PREPROCESSOR, word_match({
'allusersprofile', 'appdata', 'clientname', 'cmdcmdline', 'cmdextversion', 'comspec', 'commonprogramfiles', 'computername', 'errorlevel', 'homedrive', 'homepath', 'localappdata','logonserver', 'number_of_processors', 'os', 'path', 'pathext', 'processor_architecture', 'processor_identifier', 'processor_level', 'processor_revision', 'programfiles', 'random', 'sessionname', 'systemdrive', 'systemroot','temp', 'tmp', 'userdnsdomain', 'userdomain', 'username', 'userprofile', 'windir', 'on', 'off'
}, nil, true))

-- % Variables.
local var= token(l.PREPROCESSOR, B('%') * (l.digit + '%' * l.alpha) + l.delimited_range('%', true, true))

-- Labels.
local lable_kw = P('call') + P('goto') * l.space * l.word
local lable_id =':' * l.word
local my_lable =  token(l.PREPROCESSOR,  lable_kw  + lable_id)

-- Strings.
local dq_str = l.delimited_range('"', true, true)
local sq_str = l.delimited_range("'", true, true)
local str = token(l.STRING, dq_str + sq_str)

-- Hide Operator
local unecho = token('unecho', '@' )

-- Numbers.
local nbr = token(l.NUMBER, l.float + l.integer)

-- Operators.
local oper = token(l.OPERATOR, S('+-|&<>=?():'))

M._rules = {
  {'whitespace', ws},
  {'comment', comment},
  {'keyword', kw_int},
  {'function', kw_ext},
  {'operator', oper},
  {'string', str},
  {'variable', var},
  {'preprocessor', kw_env},
  {'number', nbr},
  {'lable', my_lable},
  {'type', my_generics},
  {'unecho', unecho}
}

M._foldsymbols = {
 [l.KEYWORD] = { ['setlocal'] = 1, ['endlocal'] = -1 },
 [l.OPERATOR] =  { ['('] = 1, [')'] = -1},
 [l.COMMENT] = { ['REM'] = l.fold_line_comments('REM') , ['::'] = l.fold_line_comments('::')},
 _patterns = {'():' , '%l+'}
}

l.case_insensitive_fold_points = true

return M
