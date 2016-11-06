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
    let r = t.globalRect + (if s.ignoresCamera: vec() else: camera.offset)
    renderer.setDrawColor s.color
    renderer.fillRect r

  entities.forComponents e, [
    Transform, t,
    Text, text,
  ]:
    let r = t.globalPos + (if text.ignoresCamera: vec() else: camera.offset)
    if text.cachedText == nil:
      new text.cachedText
      text.cachedText[] = renderer.renderText(text.getText(), text.font, text.color)
    renderer.draw text.cachedText[], r
