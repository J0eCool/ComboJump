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
    weapon,
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

proc spawnBullet(weapon: ShooterWeaponInfo, pos, vel: Vec): Entity =
  newEntity("Bullet", [
    Damage(damage: weapon.damage),
    Bullet(liveTime: 3.0),
    Collider(layer: Layer.bullet),
    Transform(
      pos: pos,
      size: vec(16),
    ),
    Movement(vel: vel),
    Sprite(color: rgb(0, 255, 72)),
    RemoveWhenOffscreen(),
  ])

proc bulletsToFire(weapon: ShooterWeaponInfo, pos: Vec): Events =
  let
    bulletSpeed = 500.0
    num = weapon.numBullets
  result = @[]
  for i in 0..<num:
    let t =
      if num == 1:
        0.0
      else:
        lerp(i / (num - 1), -1.0, 1.0)
    case weapon.kind
    of straight:
      let
        totalDist = 5.0 * num.float
        p = pos + t * vec(-sqrt(abs(t)) * sign(t).float * totalDist, totalDist)
        vel = vec(bulletSpeed, 0.0)
      result.add Event(kind: addEntity, entity: weapon.spawnBullet(p, vel))
    of spread:
      let
        totalAngle = degToRad(15.0 + 8.0 * num.float)
        angle = t * totalAngle / 2.0
        dir = unitVec(angle)
        vel = dir * bulletSpeed
      result.add Event(kind: addEntity, entity: weapon.spawnBullet(pos, vel))


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
