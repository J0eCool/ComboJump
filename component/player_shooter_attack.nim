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
    leftClickCooldown: float
    qCooldown: float
  PlayerShooterAttack* = ref PlayerShooterAttackObj

defineComponent(PlayerShooterAttack, @[])

proc bulletsToFire(transform: Transform, weapon: ShooterWeapon): Events =
  let
    bulletSpeed = 500.0
    num = weapon.numBullets
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
      Damage(damage: weapon.damage),
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
    attack.leftClickCooldown -= dt
    attack.qCooldown -= dt
    if input.isMouseHeld and attack.leftClickCooldown <= 0.0:
      attack.leftClickCooldown = 1.0 / stats.leftClickWeapon.attackSpeed
      result &= bulletsToFire(transform, stats.leftClickWeapon)
    if input.isHeld(Input.keyQ) and attack.qCooldown <= 0.0:
      attack.qCooldown = 1.0 / stats.qWeapon.attackSpeed
      result &= bulletsToFire(transform, stats.qWeapon)
