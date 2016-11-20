import
  component/movement,
  component/player_control,
  component/transform,
  entity,
  event,
  option,
  system,
  util,
  vec

type
  EnemyProximity* = ref object of Component
    targetRange*: float
    targetMinRange*: float
    isInRange: bool
    dirToPlayer: float

  EnemyMoveTowards* = ref object of Component
    moveSpeed*: float

  EnemyJumpTowards* = ref object of Component
    moveSpeed*: float
    jumpHeight*: float
    jumpDelay*: float
    jumpTimer: float

defineSystem:
  proc updateEnemyProximity*() =
    entities.forComponents e, [
      EnemyProximity, p,
      Transform, t,
    ]:
      let pc = entities.firstComponent(PlayerControl)
      if pc == nil:
        continue
      let pt = pc.entity.getComponent(Transform)
      if pt == nil:
        continue

      let
        delta = pt.pos - t.pos
        xDist = delta.x.abs
      p.isInRange = xDist.between(p.targetMinRange, p.targetRange)
      p.dirToPlayer = delta.x.sign.float

proc updateEnemyMoveTowards(entities: Entities, dt: float) =
  entities.forComponents e, [
    EnemyMoveTowards, em,
    EnemyProximity, ep,
    Movement, m,
  ]:
    if ep.isInRange:
      m.vel.x = em.moveSpeed * ep.dirToPlayer
    else:
      m.vel.x = 0

proc updateEnemyJumpTowards(entities: Entities, dt: float) =
  entities.forComponents e, [
    EnemyJumpTowards, em,
    EnemyProximity, ep,
    Movement, m,
  ]:
    if not m.onGround:
      continue

    m.vel.x = 0
    em.jumpTimer -= dt
    if em.jumpTimer >= 0:
      continue

    if ep.isInRange:
      m.vel.x = em.moveSpeed * ep.dirToPlayer
      m.vel.y = jumpSpeed(em.jumpHeight)
      em.jumpTimer = em.jumpDelay

defineSystem:
  proc updateEnemyMovement*(dt: float) =
    entities.updateEnemyMoveTowards(dt)
    entities.updateEnemyJumpTowards(dt)
