import
  sdl2

import
  component/transform,
  component/collider,
  camera,
  drawing,
  entity,
  event,
  option,
  rect,
  resources,
  system,
  util,
  vec

type
  Targeting* = object
    target*: Option[Entity]

proc draw*(renderer: RendererPtr, targeting: Targeting, camera: Camera) =
  targeting.target.bindAs tgt:
    tgt.withComponent Transform, t:
      renderer.setDrawColor color(255, 67, 81, 255)
      renderer.fillRect t.globalRect + camera.offset

defineSystem:
  proc updateTargeting*(targeting: var Targeting) =
    targeting.target.bindAs tgt:
      if not (tgt in entities):
        targeting.target = makeNone[Entity]()

    if targeting.target.isNone:
      entities.forComponents e, [
        Collider, c,
      ]:
        if c.layer == Layer.enemy:
          targeting.target = makeJust(e)
          break
