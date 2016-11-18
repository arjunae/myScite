-- test lua dbg --
print("start")

one =function(str)
   two(str)
end

two=function(str)
   print(str)
end

one("dolly")
-- .....
two('went')
two('there')

