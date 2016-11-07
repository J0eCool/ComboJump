import
  component/movement,
  component/player_control,
  component/transform,
  entity,
  event,
  option,
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

proc updateEnemyProximity*(entities: Entities): Events =
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

proc updateEnemyMovement*(entities: Entities, dt: float): Events =
  entities.forComponents e, [
    EnemyMoveTowards, em,
    EnemyProximity, ep,
    Movement, m,
  ]:
    if ep.isInRange:
      m.vel.x = em.moveSpeed * ep.dirToPlayer
    else:
      m.vel.x = 0
