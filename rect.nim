import vec

type Rect* {.pure, final.} =
  tuple[x, y, w, h: float]

proc rect*[T: SomeNumber](x, y, w, h: T): Rect =
  (x.float, y.float, w.float, h.float)

proc rect*(pos, size: Vec): Rect =
  rect(
    pos.x, pos.y,
    size.x, size.y,
  )

proc left*(rect: Rect): float =
  rect.x - rect.w / 2
proc right*(rect: Rect): float =
  rect.x + rect.w / 2
proc top*(rect: Rect): float =
  rect.y - rect.h / 2
proc bottom*(rect: Rect): float =
  rect.y + rect.h / 2

proc center*(rect: Rect): Vec =
  vec(rect.x, rect.y)

proc contains*(rect: Rect, point: Vec): bool =
  (
    point.x >= rect.left and
    point.x <= rect.right and
    point.y >= rect.top and
    point.y <= rect.bottom
  )

proc pos*(rect: Rect): Vec =
  vec(rect.x, rect.y)
proc size*(rect: Rect): Vec =
  vec(rect.w, rect.h)

proc `+`*(rect: Rect, delta: Vec): Rect =
  rect(rect.pos + delta, rect.size)
