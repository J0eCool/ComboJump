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
    shotOffset*: Vec
  PlayerShooterAttack* = ref PlayerShooterAttackObj

defineComponent(PlayerShooterAttack, @[])

proc bulletsToFire(weapon: ShooterWeaponInfo, pos: Vec): Events =
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
        pos: pos,
        size: vec(16),
      ),
      Movement(vel: dir * bulletSpeed),
      Sprite(color: rgb(0, 255, 72)),
      RemoveWhenOffscreen(),
    ]))


defineSystem:
  components = [PlayerShooterAttack, Transform]
  proc updatePlayerShooterAttack*(stats: ShooterStats, dt: float, input: InputManager) =
    proc updateWeapon(wep: var ShooterWeapon, isHeld: bool): Events =
      let info = wep.info
      wep.cooldown -= dt
      wep.reload -= dt
      if wep.reload <= 0.0:
        wep.ammo = info.maxAmmo
      let
        hasAmmo = wep.ammo > 0 or info.maxAmmo <= 0
        shouldShoot = isHeld and wep.cooldown <= 0.0 and hasAmmo
      if not shouldShoot:
        @[]
      else:
        wep.cooldown = 1.0 / info.attackSpeed
        wep.reload = info.reloadTime
        wep.ammo -= 1
        wep.info.bulletsToFire(transform.pos + playerShooterAttack.shotOffset)

    result &= updateWeapon(stats.leftClickWeapon, input.isMouseHeld)
    result &= updateWeapon(stats.qWeapon, input.isHeld(keyQ))
