import
  component/[
    movement,
    transform,
  ],
  entity,
  event,
  game_system,
  vec

type
  EnemyShooterMovementObj* = object of Component
    moveSpeed*: float
    dir: Vec
  EnemyShooterMovement* = ref EnemyShooterMovementObj

defineComponent(EnemyShooterMovement, @[])

defineSystem:
  components = [EnemyShooterMovement, Movement, Transform]
  proc updateEnemyShooterMovement*(dt: float) =
    discard
