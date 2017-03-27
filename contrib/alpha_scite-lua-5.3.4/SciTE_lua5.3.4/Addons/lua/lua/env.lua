--print("lua: env.lua loaded")
 scite_Command('printenv|printenv|Ctrl+1')
     
 function printenv()
 for n in pairs(_G) do print(n) end 
 end 

 scite_Command('test_buffer|test_buffer|Ctrl+2') 
 function test_buffer()
 print(tostring(buffer.test)) 
 buffer.test="heyBuffer" 
 print (tostring(buffer.test) )
 end 