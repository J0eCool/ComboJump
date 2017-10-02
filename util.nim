import macros, math, random

macro dprint*(exprs: varargs[typed]): untyped =
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

# generates a random float between lo and hi, not including hi
proc random*(lo, hi: float): float =
  random(hi - lo) + lo

# generates a random int between lo and hi, including hi
proc random*(lo, hi: int): int =
  random(hi - lo + 1) + lo

proc randomNormal*(lo, hi: float): float =
  let
    a = random(lo, hi)
    b = random(lo, hi)
    lo = min(a, b)
    hi = max(a, b)
  random(lo, hi)

proc randomBool*(probability = 0.5): bool =
  random(0.0, 1.0) < probability

proc random*[T](list: seq[T]): T =
  list[random(0, list.len - 1)]

proc random*[T: enum](): T =
  T(random(ord(low(T)), ord(high(T))))

proc randomSubset*[T](list: seq[T], count: int): seq[T] =
  let clampedCount = min(list.len, count)
  var copied: seq[T]
  copied.deepCopy(list)
  result = @[]
  for i in 0..<clampedCount:
    let item = random(copied)
    result.add item
    copied.remove(item)

proc shuffle*[T](list: var seq[T]) =
  for i in 0..<list.len:
    let j = random(i, list.len - 1)
    swap(list[i], list[j])

proc remove*[T](list: var seq[T], item: T) =
  let index = list.find(item)
  if index >= 0:
    list.delete(index)

proc mustRemove*[T](list: var seq[T], item: T) =
  let index = list.find(item)
  assert index >= 0, "Did not find item to remove"
  list.delete(index)

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

macro addVarargs*(call, args: untyped): untyped =
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

proc approxEq*(a, b: seq[float], epsilon=0.00001): bool =
  if a.len != b.len:
    return false
  for i in 0..<a.len:
    if not a[i].approxEq(b[i]):
      return false
  return true

proc newOf*[T](item: T): ref T =
  new(result)
  result[] = item

proc allOf*[T: enum](): seq[T] =
  result = @[]
  for item in T:
    result.add item
