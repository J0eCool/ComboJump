import
  entity,
  rect,
  vec

type
  TransformObj* = object of Component
    pos*, size*, scale*: Vec
  Transform* = ref TransformObj

defineComponent(Transform, @[])

proc rect*(t: Transform): Rect =
  rect(t.pos, t.size)
proc `rect=`*(t: Transform, r: Rect) =
  t.pos = r.pos
  t.size = r.size

proc parent(transform: Transform): Transform =
  if transform.entity.parent != nil:
    return transform.entity.parent.getComponent(Transform)

proc scaleOrDefault*(transform: Transform): Vec =
  if transform.scale == vec(0):
    vec(1)
  else:
    transform.scale

proc globalScale*(transform: Transform): Vec =
  if transform.parent == nil:
    transform.scaleOrDefault
  else:
    transform.parent.globalScale * transform.scaleOrDefault

proc globalPos*(transform: Transform): Vec =
  if transform.parent == nil:
    return transform.pos
  let parent = transform.parent()
  return parent.globalPos + parent.globalScale * transform.pos
proc `globalPos=`*(transform: Transform, pos: Vec) =
  if transform.parent == nil:
    transform.pos = pos
    return
  let parentPos = transform.parent().globalPos
  # TODO: incorporate parent.globalScale
  transform.pos = pos - parentPos

proc globalSize*(transform: Transform): Vec =
  transform.size * transform.globalScale

proc globalRect*(t: Transform): Rect =
  rect(t.globalPos, t.globalSize)
