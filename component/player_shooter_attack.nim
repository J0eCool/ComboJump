import math

import
  component/[
    bullet,
    collider,
    damage_component,
    movement,
    remove_when_offscreen,
    sprite,
    transform,
  ],
  quick_shoot/[
    shooter_stats,
  ],
  color,
  entity,
  event,
  game_system,
  input,
  vec,
  util

type
  PlayerShooterAttackObj* = object of ComponentObj
    shotCooldown: float
  PlayerShooterAttack* = ref PlayerShooterAttackObj

defineComponent(PlayerShooterAttack, @[])

proc bulletsToFire(transform: Transform, stats: ShooterStats): Events =
  let
    bulletSpeed = 500.0
    num = stats.numBullets
    totalAngle = degToRad(15.0 + 8.0 * num.float)
  result = @[]
  for i in 0..<num:
    let
      angle =
        if num == 1:
          0.0
        else:
          lerp(i / (num - 1), -1.0, 1.0) * totalAngle / 2.0
      dir = unitVec(angle)
    result.add Event(kind: addEntity, entity: newEntity("Bullet", [
      Damage(damage: stats.damage),
      Bullet(liveTime: 3.0),
      Collider(layer: Layer.bullet),
      Transform(
        pos: transform.pos,
        size: vec(16),
      ),
      Movement(vel: dir * bulletSpeed),
      Sprite(color: rgb(0, 255, 72)),
      RemoveWhenOffscreen(),
    ]))

defineSystem:
  components = [PlayerShooterAttack, Transform]
  proc updatePlayerShooterAttack*(stats: ShooterStats, dt: float, input: InputManager) =
    let attack = playerShooterAttack
    attack.shotCooldown -= dt
    if input.isMouseHeld and attack.shotCooldown <= 0.0:
      attack.shotCooldown = 1.0 / stats.attackSpeed
      result &= bulletsToFire(transform, stats)
