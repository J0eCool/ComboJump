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
  TargetKind* = enum
    noTarget
    posTarget
    entityTarget
  Target* = object
    case kind*: TargetKind
    of noTarget:
      discard
    of posTarget:
      pos*: Vec
    of entityTarget:
      entity*: Entity

  Targeting* = ref object of Component
    target*: Target

proc tryPos*(target: Target): Option[Vec] =
  case target.kind
  of noTarget:
    makeNone[Vec]()
  of posTarget:
    makeJust(target.pos)
  of entityTarget:
    makeJust(target.entity.getComponent(Transform).pos)

defineDrawSystem:
  proc drawTargeting*(camera: Camera) =
    entities.forComponents e, [
      Targeting, t,
    ]:
      t.target.tryPos.bindAs pos:
        renderer.setDrawColor color(255, 67, 81, 255)
        renderer.fillRect rect(pos, vec(50)) + camera.offset

defineSystem:
  proc updateTargeting*() =
    entities.forComponents e, [
      Targeting, targeting,
    ]:
      if targeting.target.kind == entityTarget:
        if not (targeting.target.entity in entities):
          targeting.target = Target(kind: noTarget)

      if targeting.target.kind == noTarget:
        entities.forComponents e, [
          Collider, c,
        ]:
          if c.layer == Layer.enemy:
            targeting.target = Target(kind: entityTarget, entity: e)
            break
