import
  component/enemy_proximity,
  component/movement,
  component/transform,
  entity,
  event,
  game_system,
  option,
  util,
  vec

type
  EnemyMoveTowards* = ref object of Component
    moveSpeed*: float

defineSystem:
  components = [EnemyMoveTowards, EnemyProximity, Movement]
  proc updateEnemyMoveTowards*(dt: float) =
    if enemyProximity.isInRange and not enemyProximity.isAttacking:
      movement.vel = enemyMoveTowards.moveSpeed * enemyProximity.dirToPlayer
    else:
      movement.vel = vec(0)
