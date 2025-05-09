-- go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
spawner_path = props["spawner.extension.path"]
fn,err = package.loadlib(spawner_path..'\\spawner-ex.dll','luaopen_spawner')
if fn then fn() end -- register spawner

--Liest so lange weiter, bis eine vollständige Zeile mit \n empfangen wurde.
-- ansonsten werden auch Teilzeilen oder fragmentierte Blöcke sofort ausgegeben.
spawner.fulllines(1)

print("popen readall sample")
spawn=spawner.popen("dir /b "..props["FilePath"])
if not spawn or not spawn.lines then 
print("Sfailure")
print(spawn.lines)
end
local all = spawn:read("*a")
print("Alles:", all)
spawn:close()



print("popen2 readbyline sample")
local writer, reader = spawner.popen2("cmd")

writer:write("echo Lua + popen2\r\n")
writer:write("exit\r\n")
writer:flush()

while true do
  local line = reader:read("*l")
  if not line then break end
  print("->", line)
end
writer:close()
reader:close()

