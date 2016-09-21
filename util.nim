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
