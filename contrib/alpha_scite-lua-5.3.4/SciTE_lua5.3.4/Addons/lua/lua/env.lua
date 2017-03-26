--print("lua: env.lua loaded")
 scite_Command('printenv|printenv|Ctrl+1')
      
 function printenv()
 
 for n in pairs(_G) do print(n) end 
 end 