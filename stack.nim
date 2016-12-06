type Stack[T] = object
  list: seq[T]

proc newStack*[T](): Stack[T] =
  result.list = newSeq[T]()
proc count*[T](stack: Stack[T]): int =
  stack.list.len
proc push*[T](stack: var Stack[T], item: T) =
  stack.list.add item
proc pop*[T](stack: var Stack[T]): T =
  stack.list.del(stack.count - 1)
proc peek*[T](stack: Stack[T]): T =
  stack[stack.count - 1]
