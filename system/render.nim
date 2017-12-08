import
  sdl2,
  sdl2.ttf

import
  component/collider,
  component/sprite,
  component/text,
  component/transform,
  camera,
  drawing,
  entity,
  game_system,
  rect,
  resources,
  vec

defineDrawSystem:
  proc renderSystem*(camera: Camera) =
    entities.forComponents e, [
      Transform, t,
      Sprite, s,
    ]:
      let r = t.globalRect + (if s.ignoresCamera: vec() else: camera.offset)
      if s.sprite != nil:
        let
          flip = s.flipX xor s.flipAssetX
          clip =
            if s.clipRect == rect():
              s.sprite.size
            else:
              s.clipRect
        renderer.draw s.sprite, r, clip, flip, s.angle
      else:
        renderer.fillRect r, s.color

    entities.forComponents e, [
      Transform, t,
      Text, text,
    ]:
      if text.font != nil:
        let
          pos = t.globalPos + (if text.ignoresCamera: vec() else: camera.offset)
        renderer.drawCachedText(text.text, pos, text.font, text.color)
