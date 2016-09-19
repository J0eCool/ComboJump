import sdl2

import
  component/collider,
  component/sprite,
  component/transform,
  entity,
  rect,
  vec

proc sdlRect(r: rect.Rect): sdl2.Rect =
  rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr) =
  forComponents(entities, e, [
    Transform, t,
    Sprite, s,
  ]):
    var rect = sdlRect(t.rect)
    renderer.setDrawColor(s.color)
    renderer.fillRect(rect)
