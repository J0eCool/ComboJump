import
  component/collider,
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
    attackRange*: float
    isInRange*: bool
    isInAttackRange*: bool
    dirToPlayer*: Vec
    isAttacking*: bool

  EnemyJumpTowards* = ref object of Component
    moveSpeed*: float
    jumpHeight*: float
    jumpDelay*: float
    jumpTimer: float

defineSystem:
  proc updateEnemyProximity*(player: Entity) =
    let pt = if player == nil: nil else: player.getComponent(Transform)

    entities.forComponents e, [
      EnemyProximity, p,
      Transform, t,
    ]:
      if pt == nil:
        p.isInRange = false
        p.isInAttackRange = false
        continue

      let
        delta = pt.pos - t.pos
        dist = delta.length.abs
      p.isInRange = dist.between(p.targetMinRange, p.targetRange)
      p.isInAttackRange = dist <= p.attackRange
      p.dirToPlayer = delta.unit
