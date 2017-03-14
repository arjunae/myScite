# pop returns the last element and removes it from the array
alpha = ["a","b","c","d","e","f"]
puts "pop="+alpha.pop   # pop=f
puts alpha.inspect      # ["a", "b", "c", "d", "e"]

class Person
  def initialize(fname, lname)
   @fname = fname
   @lname = lname
  end
end
person = Person.new("Augustus","Bondi")
print person
