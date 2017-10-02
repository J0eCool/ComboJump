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
  EnemyShooterMovementKind* = enum
    moveStraight
    moveSine
  EnemyShooterMovementData* = object
    case kind: EnemyShooterMovementKind
    of moveStraight:
      discard
    of moveSine:
      period: float
      sineDir: Vec
    dir: Vec
    moveSpeed: float
  EnemyShooterMovementObj* = object of Component
    data*: EnemyShooterMovementData
    t: float
  EnemyShooterMovement* = ref EnemyShooterMovementObj

defineComponent(EnemyShooterMovement, @["data"])

defineSystem:
  components = [EnemyShooterMovement, Movement, Transform]
  proc updateEnemyShooterMovement*(dt: float) =
    let
      move = enemyShooterMovement
      data = move.data
    move.t += dt
    movement.vel = data.moveSpeed * (
      case data.kind
      of moveStraight:
        data.dir
      of moveSine:
        let angle = 2 * PI * move.t / data.period
        data.sineDir * sin(angle) + data.dir
    )

proc straight*(dir: Vec, speed: float): EnemyShooterMovementData =
  EnemyShooterMovementData(
    kind: moveStraight,
    dir: dir,
    moveSpeed: speed,
  )

proc sine*(dir: Vec, speed: float, sineDir: Vec, period: float): EnemyShooterMovementData =
  EnemyShooterMovementData(
    kind: moveSine,
    sineDir: sineDir,
    period: period,
    dir: dir,
    moveSpeed: speed,
  )
