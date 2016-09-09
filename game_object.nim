import sdl2

import vec

type GameObject* = ref object
  pos, size: Vec
  color: Color
  renderer: RendererPtr

proc newGameObject*(pos, size: Vec, renderer: RendererPtr): GameObject =
  new result
  result.pos = pos
  result.size = size
  result.color = color(255, 32, 32, 255)
  result.renderer = renderer

proc move*(obj: GameObject, dpos: Vec) =
  obj.pos += dpos

proc draw*(obj: GameObject) =
  obj.renderer.setDrawColor(obj.color)
  var r = rect(obj.pos, obj.size)
  obj.renderer.fillRect(r)
