import macros, math, random

type Vec* {.pure, final.} =
  tuple[x, y: float]

proc vec*[T: SomeNumber](x, y: T): Vec =
  (x.float, y.float)
proc vec*[T: SomeNumber](s: T): Vec =
  (s.float, s.float)

template vecf(op, assignOp: expr): expr =
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

proc randomVec*(r: float): Vec =
  unitVec(random(2 * PI)) * random(r)
