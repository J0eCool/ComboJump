type Stack[T] = object
  list: seq[T]

proc newStack*[T](): Stack[T] =
  result.list = newSeq[T]()

proc count*[T](stack: Stack[T]): int =
  stack.list.len

proc push*[T](stack: var Stack[T], item: T) =
  stack.list.add item

proc pop*[T](stack: var Stack[T]): T =
  result = stack.list[stack.count - 1]
  stack.list.del(stack.count - 1)

proc peek*[T](stack: Stack[T]): T =
  stack.list[stack.count - 1]

proc `$`*[T](stack: Stack[T]): string =
  $stack.list
