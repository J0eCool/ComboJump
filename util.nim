import macros, math, random

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
proc random*(lo, hi: int): int =
  random(hi - lo + 1) + lo

proc randomNormal*(lo, hi: float): float =
  let
    a = random(lo, hi)
    b = random(lo, hi)
    lo = min(a, b)
    hi = max(a, b)
  random(lo, hi)

proc random*[T](list: seq[T]): T =
  list[random(0, list.len - 1)]
  
proc shuffle*[T](list: var seq[T]) =
  for i in 0..<list.len:
    let j = random(i, list.len - 1)
    swap(list[i], list[j])

proc remove*[T](list: var seq[T], item: T) =
  let index = list.find(item)
  if index >= 0:
    list.del(index)

proc removeAll*[T](list: var seq[T], items: seq[T]) =
  for i in items:
    list.remove(i)

proc lerp*(t, lo, hi: float): float =
  let u = clamp(t, 0, 1)
  u * (hi - lo) + lo
proc lerp*(t: float, lo, hi: int): int =
  t.lerp(lo.float, hi.float).round.int

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

macro addVarargs*(call, args: expr): expr =
  result = call
  for arg in args:
    result.add arg

proc between*[T](val, lo, hi: T): bool =
  val >= lo and val <= hi

proc `min=`*[T](a: var T, b: T) =
  a = min(a, b)
proc `max=`*[T](a: var T, b: T) =
  a = max(a, b)

proc newSeqOf*[T](base: T): seq[T] =
  @[base]

proc formatFloat*(num: float): string =
  ($num)[0..4]

proc approxEq*(a, b: float, epsilon=0.00001): bool =
  abs(a - b) <= epsilon
