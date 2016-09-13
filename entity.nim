import sdl2

import vec

type Entity* = ref object of RootObj
  pos*, size*: Vec
  color*: Color

proc newEntity*(pos, size: Vec): Entity =
  new result
  result.pos = pos
  result.size = size
  result.color = color(255, 32, 32, 255)

proc move*(obj: Entity, dpos: Vec) =
  obj.pos += dpos

proc draw*(renderer: RendererPtr, obj: Entity) =
  var rect = rect(obj.pos, obj.size)
  renderer.setDrawColor(obj.color)
  renderer.fillRect(rect)
