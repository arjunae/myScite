-- go@ dofile $(FilePath)
-- ^^tell Scite to use its internal Lua interpreter.
spawner_path = props["spawner.extension.path"]
fn,err = package.loadlib(spawner_path..'\\spawner-ex.dll','luaopen_spawner')
if fn then fn() end -- register spawner
spawner.verbose(true)
spawner.fulllines(1)
--test1
spawn=spawner.popen("dir /b "..props["FilePath"])
if not spawn or not spawn.lines then return end
for line in spawn:lines() do
if line==string.match(line,"(\s.*)") then print("popen test ok - result was: "..line) end
end
--test2
spawner_obj = spawner.new("cmd.exe")
if spawner_obj:run()==true then print("spawner.new test Ok") end
spawner_obj:write('exit\n')


