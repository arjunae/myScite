Mitchell's SciTE Tools Modules

Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

SciTE-tools homepage: http://caladbolg.net/scite.php
Send email to: mitchell<att>caladbolg<dott>net

All Lua and Ruby scripts are copyrighted by Mitchell Foral.
Permission is granted to use, copy, modify, and distribute
these files provided credit is given to Mitchell.

Description:
  These modules serve to extend SciTE's default capabilities with very powerful
  text-editing utilities and modes. As their names suggest, modules can be
  loaded on demand, and you can load whichever ones you want; it doesn't have
  to be all of them.

Requirements:
  Some Lua scripts (in particular snippets.lua) utilize the Ruby programming
  language. If it is not installed on your system, you can get it from
  http://ruby-lang.org.

Installation:
  The modules can be placed in any directory you specify, as long as your Lua
  startup script adds that directory to the 'package.path' Lua variable so you
  can 'require' them.

Usage:
  Loading a module on demand is as simple as a Lua 'require' statement. A
  description of the statement is available via the Lua 5.1 Reference Manual
  (http://www.lua.org/manual/5.1/).

  All modules are stored in the global 'modules' table after they are
  'require'd. Each directory is the name of a specific module located in that
  table (e.g. modules.scite refers to the Lua scripts in the scite/ directory).
  A simple Lua startup script might look like this:

    PLATFORM = 'linux' -- or 'windows'
    if PLATFORM == 'linux' then
      LUA_PATH = props['SciteDefaultHome']..'/scripts/?.lua'
    elseif PLATFORM == 'windows' then
      LUA_PATH = props['SciteDefaultHome']..'\\scripts\\?.lua'
    end
    package.path  = package.path..';'..LUA_PATH

    require 'scite/scite' -- load scite module

  There are a few things to note about this example:
    1: There is a global PLATFORM variable. It is used for most modules to set
      platform-specific options, but only needs to be set globally once,
      because its value is inherited in other modules.
    2: The '?' gets replaced by the argument to 'require'.
    3: You might see some redundancy in the fact that 'scite/scite' is being
      loaded. The first 'scite' is the directory, and the second is the module
      loader script that happens to have the same name as the directory for
      clarity. If it really bugs you, you could move each module loader a
      directory level up.

  You can load modules on a per-language basis as well via an extension script.
  As an example,
    extension.*.lua=$(SciteDefaultHome)/scripts/lua/lua.lua
  loads the Lua module (located in the lua/ directory) when editing a Lua file.
  Taking a look at the lua.lua script, you'll see that 'commands.lua' is loaded
  on init. This means all Lua- specific commands are accessible via the
  modules.lua.commands table. This same idea applies to all modules.

  For more information on how to setup startup and extension scripts, please
  see the SciTE documentation at http://scintilla.sf.net/SciTEDoc.html.

  Module commands can be invoked in one of two ways: via the SciTE Tools menu,
  or by key command. If you'd like to use the Tools menu, add a command like
  you would normally in SciTE, but prepend 'dostring' before the function call.
    e.g. command.1.*=dostring modules.scite.snippets.insert()
  If you'd like to use a key command, scite/key_commands.lua would be an
  optimal place to put it. There are good examples in that file to give you an
  idea of how to declare one. For more information about key commands, please
  read doc/keys_doc.txt.

Notes:
  If key commands are not working expected, check key_commands.lua (in
  scripts/scite/) and make sure the ALTERNATIVE_KEYS flag is set to false. I
  occasionally forget to reset the flag when I commit.

Additional Documentation:
  * Snippets and key commands documentation can be found in scripts/doc/.
  * Each of the Lua modules has inline documentation for every function and the
    LuaDocs can be found at:
    - http://caladbolg.net/scite/luadoc/scripts/index.html

Examples:
  Examples on setting extension and startup scripts and calling modules via the
  tool menu and via key commands can be seen in the scite-st branch of my SVN
  repository.
    http://scite-tools.googlecode.com/svn/branches/scite-st
