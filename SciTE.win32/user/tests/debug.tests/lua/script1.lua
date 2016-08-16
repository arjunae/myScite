--test lua dbg--

function two(x)
   print(x)
end

function one(y)
str_a="go"
str_b="there"
 
   two(y)
   two(str_a)
   print(str_b)
end


one('dolly')
-- .....
two('dolly')
two('went')
two('there')




