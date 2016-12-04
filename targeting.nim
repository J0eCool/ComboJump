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
  Targeting* = ref object of Component
    target*: Option[Entity]

defineDrawSystem:
  proc drawTargeting*(camera: Camera) =
    entities.forComponents e, [
      Targeting, t,
    ]:
      t.target.bindAs tgt:
        tgt.withComponent Transform, t:
          renderer.setDrawColor color(255, 67, 81, 255)
          renderer.fillRect t.globalRect + camera.offset

defineSystem:
  proc updateTargeting*() =
    entities.forComponents e, [
      Targeting, targeting,
    ]:
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
