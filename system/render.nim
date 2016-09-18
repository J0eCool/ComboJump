import sdl2

import component/transform,
       component/sprite,
       entity,
       vec

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr) =
  forComponents(entities, e, [
    Transform, t,
    Sprite, s,
  ]):
    var rect = rect(t.pos, t.size)
    renderer.setDrawColor(s.color)
    renderer.fillRect(rect)
