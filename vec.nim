import macros, math, random
import util

type Vec* {.pure, final.} =
  tuple[x, y: float]

proc vec*[T: SomeNumber](x, y: T): Vec =
  (x.float, y.float)
proc vec*[T: SomeNumber](s: T): Vec =
  (s.float, s.float)
proc vec*(): Vec =
  (0.0, 0.0)

proc vecX*(v: Vec): Vec =
  vec(v.x, 0.0)
proc vecY*(v: Vec): Vec =
  vec(0.0, v.y)

template vecf(op, assignOp: untyped): untyped =
  proc op*(a, b: Vec): Vec =
    vec(op(a.x, b.x),
        op(a.y, b.y))
  proc op*(s: SomeNumber, v: Vec): Vec =
    vec(op(s.float, v.x),
        op(s.float, v.y))
  proc op*(v: Vec, s: SomeNumber): Vec =
    vec(op(v.x, s.float),
        op(v.y, s.float))

  proc assignOp*(v: var Vec, delta: Vec) =
    v = op(v, delta)

vecf `+`, `+=`
vecf `-`, `-=`
vecf `*`, `*=`
vecf `/`, `/=`
vecf pow, `pow=`
vecf min, `min=`
vecf max, `max=`

proc unitVec*(angle: float): Vec =
  vec(cos(angle), sin(angle))

proc length2*(v: Vec): float =
  v.x * v.x + v.y * v.y
proc length*(v: Vec): float =
  v.length2().sqrt()

proc distance2*(a, b: Vec): float =
  (b - a).length2()
proc distance*(a, b: Vec): float =
  (b - a).length()

proc unit*(v: Vec): Vec =
  let mag = v.length()
  if mag == 0:
    vec(0)
  else:
    v / mag

proc angle*(v: Vec): float =
  arctan2(v.y, v.x)

proc rotate*(v: Vec, ang: float): Vec =
  v.length * unitVec(v.angle + ang)

proc dot*(a, b: Vec): float =
  a.x * b.x + a.y * b.y
proc cross*(a, b: Vec): float =
  a.x * b.y - a.y * b.x

proc randomVec*(rlo, rhi: float): Vec =
  unitVec(random(2 * PI)) * random(rlo, rhi)
proc randomVec*(r: float): Vec =
  randomVec(0, r)

proc random*(lo, hi: Vec): Vec =
  vec(random(lo.x, hi.x), random(lo.y, hi.y))

proc lengthMax*(a, b: Vec): Vec =
  if a.length2 > b.length2:
    a
  else:
    b

proc lengthMin*(a, b: Vec): Vec =
  if a.length2 < b.length2:
    a
  else:
    b

proc orientation*(a, b, c: Vec): int =
  sign((b - a).cross(c - a))

proc intersects*(a, b, c, d: Vec): bool =
  (orientation(a, b, c) != orientation(a, b, d) and
   orientation(c, d, a) != orientation(c, d, b))

proc approxEq*(a, b: Vec): bool =
  a.x.approxEq(b.x) and a.y.approxEq(b.y)
