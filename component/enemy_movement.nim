import
  component/enemy_proximity,
  component/movement,
  component/transform,
  entity,
  event,
  option,
  system,
  util,
  vec

type
  EnemyMoveTowards* = ref object of Component
    moveSpeed*: float

defineSystem:
  proc updateEnemyMoveTowards*(dt: float) =
    entities.forComponents e, [
      EnemyMoveTowards, em,
      EnemyProximity, ep,
      Movement, m,
    ]:
      if ep.isInRange and not ep.isAttacking:
        m.vel = em.moveSpeed * ep.dirToPlayer
      else:
        m.vel = vec(0)
