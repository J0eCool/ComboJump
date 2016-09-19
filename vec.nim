import macros

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
  proc op*(v: Vec, s: SomeNumber): Vec {.inline.} =
    op(s, v)

  proc assignOp*(v: var Vec, delta: Vec) =
    v = op(v, delta)

vecf `+`, `+=`
vecf `-`, `-=`
vecf `*`, `*=`
vecf `/`, `/=`
