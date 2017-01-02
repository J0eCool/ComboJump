import
  component/collider,
  component/movement,
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

  EnemyMoveTowards* = ref object of Component
    moveSpeed*: float

  EnemyJumpTowards* = ref object of Component
    moveSpeed*: float
    jumpHeight*: float
    jumpDelay*: float
    jumpTimer: float

defineSystem:
  proc updateEnemyProximity*() =
    var player: Entity = nil
    for e in entities:
      let c = e.getComponent(Collider)
      if c != nil and c.layer == Layer.player:
        player = e
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

proc updateEnemyMoveTowards(entities: Entities, dt: float) =
  entities.forComponents e, [
    EnemyMoveTowards, em,
    EnemyProximity, ep,
    Movement, m,
  ]:
    if ep.isInRange and not ep.isAttacking:
      m.vel = em.moveSpeed * ep.dirToPlayer
    else:
      m.vel = vec(0)

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
      m.vel.x = em.moveSpeed * ep.dirToPlayer.x.sign.float
      m.vel.y = jumpSpeed(em.jumpHeight)
      em.jumpTimer = em.jumpDelay

defineSystem:
  proc updateEnemyMovement*(dt: float) =
    entities.updateEnemyMoveTowards(dt)
    entities.updateEnemyJumpTowards(dt)
