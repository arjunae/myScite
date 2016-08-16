
--This simple script hooks onto OnBeforeSave and creates backups of the old version of the file that is being saved. Instead of calling an external command to copy the original file perfectly, the script uses a simple loop to copy the file's content, but losing custom attributes and other metadata. If you require exact backup, consider executing an external command to make the exact copy.

--This script uses SciteExtMan.

-- NOTE: uses extman.lua
-- Limitations: silently fails, does not copy metadata
local function backupDeFile(fname)
  local BLK = 1024 * 64
  bkname = fname.."~"
  local inf = io.open(fname, "rb")
  local outf = io.open(bkname, "wb")
  if not inf or not outf then return end
  while true do
    local dat = inf:read(BLK)
    if not dat then break end
    outf:write(dat)
  end
  inf:close()
  outf:close()
end
scite_OnBeforeSave(backupDeFile)

-- KeinHongMan

You can also add the following to your SciTEGlobal.properties if all you want is a simple way to create backups of the current file.

command.name.1.*=Backup this file
command.1.*=dostring os.execute("cmd /C copy $(FileNameExt?) $(FileName?)_"..os.date("%y%m%d%H%M")..".$(FileExt?)")
command.mode.1.*=subsystem:lua,savebefore:no

-- Alan MN 