import sdl2

type Vec* {.pure, final.} = tuple[
  x, y: float
]

proc vec*[T: SomeNumber](x, y: T): Vec =
  (x.float, y.float)

template vecf(op: expr): expr =
  proc op*(a, b: Vec): Vec =
    vec(op(a.x, b.x),
        op(a.y, b.y))

template vecf_assign(op: expr): expr =
  proc op*(v: var Vec, delta: Vec) =
    v = v + delta

vecf `+`
vecf `-`
vecf `*`
vecf `/`
vecf_assign `+=`
vecf_assign `-=`
vecf_assign `*=`
vecf_assign `/=`

proc rect*(pos, size: Vec): Rect =
  rect(
    pos.x.cint, pos.y.cint,
    size.x.cint, size.y.cint,
  )
