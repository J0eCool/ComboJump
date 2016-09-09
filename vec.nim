import sdl2

type Vec* {.pure, final.} = tuple[
  x, y: float
]

proc vec*[T: SomeNumber](x, y: T): Vec =
  (x.float, y.float)

proc `+`*(a, b: Vec): Vec =
  vec(a.x + b.x, a.y + b.y)

proc `+=`*(v: var Vec, delta: Vec) =
  v = v + delta

proc rect*(pos, size: Vec): Rect =
  rect(
    pos.x.cint, pos.y.cint,
    size.x.cint, size.y.cint,
  )
