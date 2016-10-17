import entity, rect, vec

type Transform* = ref object of Component
  pos*, size*: Vec
genComponentType(Transform)

proc rect*(t: Transform): Rect =
  rect(t.pos, t.size)

proc heirarchyOrderedTransforms(t: Transform): seq[Transform] =
  result = @[t]
  var cur = t.entity.parent
  while cur != nil:
    result &= cur.getComponent(Transform)
    cur = cur.parent

proc globalPos*(transform: Transform): Vec =
  for t in transform.heirarchyOrderedTransforms():
    result += t.pos

proc globalSize*(transform: Transform): Vec =
  # TODO: scale as well as size?
  transform.size

proc globalRect*(t: Transform): Rect =
  rect(t.globalPos, t.globalSize)
