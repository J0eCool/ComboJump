import macros, random

macro dprint*(exprs: varargs[expr]): expr =
  result = newCall("echo")
  var hadPrev = false
  for e in exprs:
    if kind(e) == nnkStrLit:
      result.add(e)
      hadPrev = false
    else:
      if hadPrev:
        result.add(newStrLitNode(", "))
      let s = toStrLit(e).strVal & "="
      result.add(newStrLitNode(s), e)
      hadPrev = true

proc sign*(x: SomeNumber): int =
  if x > 0:
    1
  elif x < 0:
    -1
  else:
    0

proc random*(lo, hi: float): float =
  random(hi - lo) + lo

proc remove*[T](list: var seq[T], item: T) =
  let index = list.find(item)
  if index >= 0:
    list.del(index)

proc removeAll*[T](list: var seq[T], items: seq[T]) =
  for i in items:
    list.remove(i)

proc lerp*(t, lo, hi: float): float =
  let u = clamp(t, 0, 1)
  return u * (hi - lo) + lo

proc copy*[T: ref object](c: T): T =
  new result
  deepCopy(result, c)

proc `$`*[T: enum, V](list: array[T, V]): string =
  result = "["
  for i in T:
    if ord(i) != 0:
      result &= ", "
    result &= $i & ":" & $list[i]
  result &= "]"
