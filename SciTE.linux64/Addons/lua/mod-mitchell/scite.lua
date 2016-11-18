--[[
  Mitchell's scite.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- The scite module.
-- It provides utilities for editing text in SciTE.
module('modules.scite', package.seeall)
require 'editing'
require 'file_browser'
--require 'keys' -- important to load last todo check altGR-9 "]"

---
-- Opens specified module in SciTE.
-- @param name The name of the module.
function open_module(name)
  scite.Open( props['SciteDefaultHome']..'/Addons/lua/mod-mitchell/'..name )
end
