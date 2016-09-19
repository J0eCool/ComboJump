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
  rect.x
proc right*(rect: Rect): float =
  rect.x + rect.w
proc top*(rect: Rect): float =
  rect.y
proc bottom*(rect: Rect): float =
  rect.y + rect.h
