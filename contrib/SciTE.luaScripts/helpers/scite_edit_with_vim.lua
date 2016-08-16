
--SciTE has several weakness, a column block editing feature is one of them. I'm using Vim if I need this feature. Vim has many powerful editing features, so I'm using Vim as a second editor of SciTE with this simple lua script SciteEditWithVim.

-- Edit with Vim as an external editor of SciTE
-- 2013.03.31 by lee.sheen at gmail dot com

scite_Command {
  'Edit with Vim|EditWithVim|Alt+Shift+V',
}

function CurrentLine ()
  return editor:LineFromPosition(editor.CurrentPos) + 1
end

function EditWithVim ()
  local gvim_exe = 'C:/"Program Files"/Vim/vim73/gvim.exe'
  local cur_file_path = props['FilePath']
  local current_line = CurrentLine()
  os.execute("start " .. gvim_exe .. " " .. cur_file_path .. " +" .. current_line)
end

--Thought and suggestion: Is it possible to catch the state of os.execute - and when this editing job in vim is done, scite will automatically open the file again (after vim is closed)?
