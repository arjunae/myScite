-- Simple Lua pattern based function detection for a few languages - please improve and add more!
--   regex (lua pattern) is used to detect all function lines
--   fmt (lua pattern) is used to find a given function name

FUNCTION_TABLE = {}

----------------------------------------
-- C/C++
-- Notice: C/C++ is tricky, therefor for now just weak implementation: only works for nicely intented code
----------------------------------------
FUNCTION_TABLE['c'] = {
  regex = {
    '([%a]+[%a%d_ :]+)%s*%('
  },
  fmt = {
    '%s'
  }
}
FUNCTION_TABLE['cpp'] = FUNCTION_TABLE['c']
FUNCTION_TABLE['cxx'] = FUNCTION_TABLE['c']
FUNCTION_TABLE['cc'] = FUNCTION_TABLE['c']
FUNCTION_TABLE['mm'] = FUNCTION_TABLE['c']

----------------------------------------
-- INI
----------------------------------------
FUNCTION_TABLE['ini'] = {
  regex = {'%[([%a%d_/%\\ ]*)%]'},
  fmt = {'%%[%s%%]'}
}
FUNCTION_TABLE['project'] = FUNCTION_TABLE['ini']

----------------------------------------
-- JavaScript
----------------------------------------
FUNCTION_TABLE['js'] = {
  regex = {
    '[ \t]*function[ \t]+([%a%d_]+)', -- function foo()
    '[ \t]*([%a%d_]+)[ |\t]*=[ |\t]*function[^%%a%%d_]' -- foo = function()
  },
  fmt = {
    '[ \t]*function[ \t]+%s[^%%a%%d_]',
    '[ \t]*%s[ |\t]*=[ |\t]*function[^%%a%%d_]'
  }
}

----------------------------------------
-- Lingo
----------------------------------------
FUNCTION_TABLE['ls'] = {
  regex = {
    '[ \t]*on[ \t]+([%a%d_]+)'
  },
  fmt = {
    '[ \t]*on[ \t]+%s[^%%a%%d_]'
  }
}
FUNCTION_TABLE['lsw'] = FUNCTION_TABLE['ls']

----------------------------------------
-- Lua
----------------------------------------
FUNCTION_TABLE['lua'] = {
  regex = {
    '[ \t]*function[ \t]+([%a%d_:]+)', -- function foo()
    '[ \t]*local[ \t]+function[ \t]+([%a%d_]+)', -- local function foo()
    '[ \t]*([%a%d_]+)[ |\t]*=[ |\t]*function[ |\t]+[^%%a%%d_]', -- foo = function()
    '[ \t]*local[ \t]+([%a%d_]+)[ |\t]*=[ |\t]*function[ |\t]+[^%%a%%d_]' -- local foo = function()
  },
  fmt = {
    '[ \t]*function[ \t]+%s[^%%a%%d_:]',
    '[ \t]*local[ \t]+function[ \t]+%s[^%%a%%d_]',
    '[ \t]*%s[ |\t]*=[ |\t]*function[^%%a%%d_]',
    '[ \t]*local[ \t]+%s[ |\t]*=[ |\t]*function[^%%a%%d_]'
  }
}

----------------------------------------
-- PHP
----------------------------------------
FUNCTION_TABLE['php'] = {
  regex = {
    '[ \t]*function[ \t]+([%a%d_]*)'
  },
  fmt = {
    '[ \t]*function[ \t]+%s[^%%a%%d_]'
  }
}