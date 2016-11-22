-- ordinary stack operation

stack = class(
  function (object)
    object.is_stack = true
    object.top = 0
    object.content = {}
  end
)

function stack:push(e)
  if not self.is_stack then error("Given table is not a stack",2) end
  self.content[self.top] = e
  self.top = self.top + 1
end

function stack:pop()
  if not self.is_stack then error("Given table is not a stack",2) end
  if self.top == 0 then error("Stack underflow",2) end
  local e = self.content[self.top]
  self.top = self.top - 1
  return e
end
