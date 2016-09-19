import component, rect, vec

type Transform* = ref object of Component
  pos*, size*: Vec

proc rect*(t: Transform): Rect =
  rect(t.pos, t.size)
