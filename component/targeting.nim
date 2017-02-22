from sdl2 import RendererPtr

import
  component/transform,
  component/collider,
  camera,
  color,
  drawing,
  entity,
  event,
  game_system,
  option,
  rect,
  resources,
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

  TargetingObj* = object of ComponentObj
    target*: Target
  Targeting* = ref TargetingObj

defineComponent(Targeting, @["target"])

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
        let
          targetColor = rgb(255, 67, 81)
          targetRect = rect(pos, vec(50)) + camera.offset
        renderer.fillRect targetRect, targetColor

defineSystem:
  proc updateTargeting*() =
    entities.forComponents entity, [
      Targeting, targeting,
      Transform, transform,
    ]:
      let pos = transform.pos
      var
        closestEnemy: Entity = nil
        closestDist = 0.0
      entities.forComponents enemy, [
        Collider, collider,
        Transform, enemyTransform,
      ]:
        if collider.layer != Layer.enemy:
          continue
        let dist = (enemyTransform.pos - pos).length2
        if closestEnemy == nil or dist < closestDist:
          closestEnemy = enemy
          closestDist = dist

      if closestEnemy != nil:
        targeting.target = Target(kind: entityTarget, entity: closestEnemy)
      else:
        targeting.target = Target(kind: noTarget)
