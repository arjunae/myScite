-- Copyright 2006-2016 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Batch Lexer

local l = require('lexer')
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'batch'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local rem = (P('REM') + 'rem' + '::') * l.nonnewline_esc^0
local comment = token(l.COMMENT, rem)

-- Internal Keywords.
local kw_int = token(l.KEYWORD, word_match({
'cd', 'chdir', 'md', 'mkdir', 'cls', 'for', 'if', 'echo', 'echo.', 'move', 'copy', 'ren', 'del', 'set', 'call', 'exit',
'setlocal', 'shift', 'endlocal', 'pause', 'defined', 'exist', 'errorlevel', 'else', 'in', 'do', 'NUL', 'AUX', 'PRN',
'not', 'goto', 'pushd', 'popd'
}, nil, true))

-- External Keywords
local kw_ext = token(l.FUNCTION,  word_match({
'APPEND', 'ATTRIB', 'CHKDSK', 'CHOICE', 'DEBUG', 'DEFRAG', 'DELTREE', 'DISKCOMP', 'DISKCOPY', 'DOSKEY',
'DRVSPACE', 'EMM386', 'EXPAND', 'FASTOPEN', 'FC', 'FDISK', 'FIND', 'FORMAT', 'GRAPHICS', 'KEYB', 'LABEL',
'LOADFIX', 'MEM', 'MODE', 'MORE', 'MOVE', 'MSCDEX', 'NLSFUNC', 'POWER', 'PRINT', 'RD', 'REPLACE', 'RESTORE',
'SETVER', 'SHARE', 'SORT', 'SUBST', 'SYS', 'TREE', 'UNDELETE', 'UNFORMAT', 'VSAFE', 'XCOPY'
}, nil, true))

-- Strings.
local dq_str = l.delimited_range('"', true, true)
local sq_str = l.delimited_range("'", true, true)
local str = token(l.STRING, dq_str + sq_str)

-- Hide Operator
local unecho = token('unecho', '@' )

-- Variables.
local var= token(l.VARIABLE, '%' * (l.digit + '%' * l.alpha) + l.delimited_range('%', true, true))

-- Numbers.
local nbr = token(l.NUMBER, l.float + l.integer)

-- Labels.
local lable =  token('mylable', ':' * l.word)

-- Operators.
local oper = token(l.OPERATOR, S('+-|&<>=?:()'))

M._rules = {
  {'whitespace', ws},
  {'comment', comment},
  {'keyword', kw_int},
  {'function', kw_ext},
  {'string', str},
  {'unecho', unecho},
  {'variable', var},
  {'number', nbr},
  {'mylable', lable},
  {'operator', oper}
}

M._tokenstyles = {
  mylable = l.STYLE_KEYWORD..',italics',
}

return M
