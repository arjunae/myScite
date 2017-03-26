--print("lua: env.lua loaded")
 scite_Command('printenv|printenv|Ctrl+1')    
 function printenv()

 print("lua: list bufferData") 
 print("lua: -----------------")
 for n in pairs(buffer) do print(n) end
 print("lua: -----------------")
 print("lua: list _G")
 print("lua: -----------------")
 for n in pairs(_G) do print(n) end
 print("lua: -----------------") 
 end 