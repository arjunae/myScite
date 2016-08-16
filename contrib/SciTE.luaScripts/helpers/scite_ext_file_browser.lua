
--SciTE hasn't its own file browser, so I'm using usually an external file browser. There is an inconvenience when I'd like to open several directories of the current editing source codes. SciteExternalFileBrowser is useful in this situation.

-- Open External File Browser
-- 2013.03.31 by lee.sheen at gmail dot com

scite_Command {
  'External File Browser|ExternalFileBrowser|Alt+Shift+F',
}

function ExternalFileBrowser ()
  local cur_file_dir = props['FileDir']
  os.execute("start explorer " .. cur_file_dir)
end
