import
  sdl2,
  sdl2.ttf,
  tables

import
  component/collider,
  component/sprite,
  component/text,
  component/transform,
  camera,
  drawing,
  entity,
  rect,
  resources,
  vec

proc renderSystem*(entities: seq[Entity], renderer: RendererPtr, camera: Camera) =
  entities.forComponents e, [
    Transform, t,
    Sprite, s,
  ]:
    renderer.setDrawColor(s.color)
    renderer.fillRect(t.globalRect + camera.offset)

  entities.forComponents e, [
    Transform, t,
    Text, text,
  ]:
    renderer.drawText(text.getText(), (t.globalPos + camera.offset), text.font, text.color)
