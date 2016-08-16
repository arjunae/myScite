
--By WalterCruz
--When working with SciTE and PHP, soon I saw a necessity: Open my PHP files through the webserver, not just open the file as-is. I try to write a bash script to do that, but I get bored of this and make it with PHP. So, I began to read about Lua and I think "Why not?" So, there is !

function openbrowser()
	local f = props['FilePath']
	local s,e,path,file = string.find(f,'^(/var/www/)(.*)')
	if path == '/var/www/' then
		target = ("http://10.132.1.18/" .. file)
		firefox = ('mozilla-firefox ' .. target .. ' &')
		print("Opening  " .. target)
		--print(firefox)
		os.execute(firefox)
	else
		print("You must put your php files under /var/www in order to run them.")
	end	
end

--I saved this file as localhost.lua, loaded it with my Lua startup file and put theses lines on my SciTE User Config:

--command.go.subsystem.*.php=3
--command.go.*.php=openbrowser()
--(On my machine, the webserver root is /var/www. Note that this can be different on your own computer). 