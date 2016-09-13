import sdl2

import ../component/transform,
       ../component/sprite,
       ../entity,
       ../vec

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr) =
  for e in entities:
    let
      t = e.getComponent(Transform)
      s = e.getComponent(Sprite)
    var rect = rect(t.pos, t.size)
    renderer.setDrawColor(s.color)
    renderer.fillRect(rect)
