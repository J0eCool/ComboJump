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
  system,
  vec

var textCache = initTable[string, RenderedText]()
proc drawCachedText*(renderer: RendererPtr,
                     text: string,
                     pos: Vec,
                     font: FontPtr,
                     color: Color = color(255, 255, 255, 255)) =
  if not textCache.hasKey(text):
    textCache[text] = renderer.renderText(text, font, color)
  renderer.draw(textCache[text], pos)

defineDrawSystem:
  proc renderSystem*(camera: Camera) =
    entities.forComponents e, [
      Transform, t,
      Sprite, s,
    ]:
      let r = t.globalRect + (if s.ignoresCamera: vec() else: camera.offset)
      if s.sprite != nil:
        renderer.draw s.sprite, r, s.flipX
      else:
        renderer.setDrawColor s.color
        renderer.fillRect r

    entities.forComponents e, [
      Transform, t,
      Text, text,
    ]:
      if text.font != nil:
        let
          pos = t.globalPos + (if text.ignoresCamera: vec() else: camera.offset)
        renderer.drawCachedText(text.text, pos, text.font, text.color)
