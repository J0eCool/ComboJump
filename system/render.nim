import sdl2

import
  component/collider,
  component/sprite,
  component/transform,
  entity,
  rect,
  vec

proc sdlRect*(r: rect.Rect): sdl2.Rect =
  rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr) =
  forComponents(entities, e, [
    Transform, t,
    Sprite, s,
  ]):
    var rect = sdlRect(t.rect)
    renderer.setDrawColor(s.color)
    e.withComponent Collider, c:
      if c.collisions.len > 0:
        renderer.setDrawColor(color(255, 0, 0, 255))
    renderer.fillRect(rect)
