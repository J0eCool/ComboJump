type Stack*[T] = object
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

proc mpeek*[T](stack: var Stack[T]): var T =
  stack.list[stack.count - 1]

proc `$`*[T](stack: Stack[T]): string =
  $stack.list

iterator items*[T](stack: Stack[T]): T =
  for i in 0..<stack.list.len:
    yield stack.list[stack.list.len - i - 1]

iterator mitems*[T](stack: var Stack[T]): var T =
  for i in 0..<stack.list.len:
    yield stack.list[stack.list.len - i - 1]

proc toSeq*[T](stack: Stack[T]): seq[T] =
  stack.list
