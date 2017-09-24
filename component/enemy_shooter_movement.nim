import math

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
    t: float
  EnemyShooterMovement* = ref EnemyShooterMovementObj

defineComponent(EnemyShooterMovement, @[])

defineSystem:
  components = [EnemyShooterMovement, Movement, Transform]
  proc updateEnemyShooterMovement*(dt: float) =
    let move = enemyShooterMovement
    move.t += dt
    movement.vel = move.moveSpeed * vec(sin(2 * PI * move.t * 0.8) - 1.0, 1.5).unit
