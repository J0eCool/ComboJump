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

var textCache = initTable[string, RenderedText]()

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
    let
      r = t.globalPos + (if text.ignoresCamera: vec() else: camera.offset)

    if not textCache.hasKey(text.text):
      textCache[text.text] = renderer.renderText(text.text, text.font, text.color)
    renderer.draw textCache[text.text], r
