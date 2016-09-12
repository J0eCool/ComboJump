import sdl2

import vec

type GameObject* = ref object of RootObj
  pos*, size*: Vec
  color*: Color

proc newGameObject*(pos, size: Vec): GameObject =
  new result
  result.pos = pos
  result.size = size
  result.color = color(255, 32, 32, 255)

proc move*(obj: GameObject, dpos: Vec) =
  obj.pos += dpos

proc draw*(renderer: RendererPtr, obj: GameObject) =
  var rect = rect(obj.pos, obj.size)
  renderer.setDrawColor(obj.color)
  renderer.fillRect(rect)
