print("lua: env.lua loaded")
  
 function printenv()
 for n in pairs(_G) do print(n) end 
 end 