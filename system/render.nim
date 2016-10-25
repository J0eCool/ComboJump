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
    if text.cachedText == nil:
      new text.cachedText
      text.cachedText[] = renderer.renderText(text.getText(), text.font, text.color)
    renderer.draw(text.cachedText[], (t.globalPos + camera.offset))
