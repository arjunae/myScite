-- test lua dbg => first start the debugger, then set the breakpoints.--
print("test")

one=function(str)
   two(str)
end

two=function(str)
   print(str)
end

one("dolly")
-- .....
two('went')
two('there')