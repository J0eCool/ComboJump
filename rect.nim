import vec

type Rect* {.pure, final.} =
  tuple[x, y, w, h: float]

proc rect*(): Rect =
  (0.0, 0.0, 0.0, 0.0)
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

proc `left=`*(rect: var Rect, pos: float) =
  rect.x = pos + rect.w / 2
proc `right=`*(rect: var Rect, pos: float) =
  rect.x = pos - rect.w / 2
proc `top=`*(rect: var Rect, pos: float) =
  rect.y = pos + rect.h / 2
proc `bottom=`*(rect: var Rect, pos: float) =
  rect.y = pos - rect.h / 2

proc center*(rect: Rect): Vec =
  vec(rect.x, rect.y)

proc topLeft*(rect: Rect): Vec =
  vec(rect.left, rect.top)
proc topRight*(rect: Rect): Vec =
  vec(rect.right, rect.top)
proc bottomLeft*(rect: Rect): Vec =
  vec(rect.left, rect.bottom)
proc bottomRight*(rect: Rect): Vec =
  vec(rect.right, rect.bottom)

proc centerLeft*(rect: Rect): Vec =
  vec(rect.left, rect.y)
proc centerRight*(rect: Rect): Vec =
  vec(rect.right, rect.y)
proc centerTop*(rect: Rect): Vec =
  vec(rect.x, rect.top)
proc centerBottom*(rect: Rect): Vec =
  vec(rect.x, rect.bottom)

proc contains*(rect: Rect, point: Vec): bool =
  (
    point.x >= rect.left  and
    point.x <= rect.right and
    point.y >= rect.top   and
    point.y <= rect.bottom
  )

proc intersects*(a, b: Rect): bool =
  return
    a.left   <= b.right  and
    a.right  >= b.left   and
    a.top    <= b.bottom and
    a.bottom >= b.top

proc pos*(rect: Rect): Vec =
  vec(rect.x, rect.y)
proc `pos=`*(rect: var Rect, pos: Vec) =
  rect.x = pos.x
  rect.y = pos.y
proc size*(rect: Rect): Vec =
  vec(rect.w, rect.h)

proc `+`*(rect: Rect, delta: Vec): Rect =
  rect(rect.pos + delta, rect.size)
proc `+=`*(rect: var Rect, delta: Vec) =
  rect = rect + delta
proc `-`*(rect: Rect, delta: Vec): Rect =
  rect(rect.pos - delta, rect.size)
proc `-=`*(rect: var Rect, delta: Vec) =
  rect = rect - delta
