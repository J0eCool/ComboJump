import
  component/movement,
  component/player_control,
  component/transform,
  entity,
  event,
  option,
  util,
  vec

type EnemyMovement* = ref object of Component
  targetRange*: float
  targetMinRange*: float
  moveSpeed*: float
  startPos: Option[Vec]

proc updateEnemyMovement*(entities: Entities, dt: float): Events =
  entities.forComponents e, [
    EnemyMovement, em,
    Movement, m,
    Transform, t,
  ]:
    let p = entities.firstComponent(PlayerControl)
    if p == nil:
      continue
    let pt = p.entity.getComponent(Transform)
    if pt == nil:
      continue

    let
      delta = pt.pos - t.pos
      xDist = delta.x.abs
    if xDist.between(em.targetMinRange, em.targetRange):
      m.vel.x = em.moveSpeed * delta.x.sign.float
    else:
      m.vel.x = 0
