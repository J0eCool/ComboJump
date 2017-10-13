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

proc bulletsToFire(weapon: ShooterWeapon, pos: Vec): Events =
  let
    info = weapon.info
    num = info.numBullets
  result = @[]
  for i in 0..<num:
    let t =
      if num == 1:
        0.0
      else:
        lerp(i / (num - 1), -1.0, 1.0)
    case info.kind
    of straight:
      let
        off = t * info.totalSpacing * vec(-sqrt(abs(t)) * sign(t).float, 0.0)
        vel = vec(info.bulletSpeed, 0.0)
      result.add Event(kind: addEntity, entity: info.spawnBullet(pos + off, vel))
    of spread:
      let
        angle = t * info.totalAngle.degToRad / 2.0
        vel = info.bulletSpeed * unitVec(angle)
      result.add Event(kind: addEntity, entity: info.spawnBullet(pos, vel))
    of gatling:
      let
        n = (weapon.numFired + i * info.numBarrels div num) / info.numBarrels
        barrelAngle = 2 * PI * n + info.barrelOffset.degToRad
        ang = weapon.t * info.barrelRotateSpeed.degToRad + barrelAngle
        off = info.barrelSize * unitVec(ang)
        vel = vec(info.bulletSpeed, 0.0)
      result.add Event(kind: addEntity, entity: info.spawnBullet(pos + off, vel))

defineSystem:
  components = [PlayerShooterAttack, Transform]
  proc updatePlayerShooterAttack*(stats: ShooterStats, dt: float, input: InputManager) =
    proc updateWeapon(wep: var ShooterWeapon, isHeld: bool): Events =
      let info = wep.info
      wep.t += dt
      wep.cooldown -= dt
      wep.reload -= dt
      if wep.reload <= 0.0:
        wep.ammo = info.maxAmmo
      let
        hasAmmo = wep.ammo > 0 or info.maxAmmo <= 0
        shouldShoot = isHeld and wep.cooldown <= 0.0 and hasAmmo
      if not shouldShoot:
        return @[]
      wep.cooldown = 1.0 / info.attackSpeed
      wep.reload = info.reloadTime
      wep.ammo -= 1
      wep.numFired += 1
      wep.bulletsToFire(transform.pos + playerShooterAttack.shotOffset)

    result &= updateWeapon(stats.leftClickWeapon, input.isMouseHeld(mouseLeft))
    result &= updateWeapon(stats.rightClickWeapon, input.isMouseHeld(mouseRight))
    result &= updateWeapon(stats.qWeapon, input.isHeld(keyQ))
    result &= updateWeapon(stats.wWeapon, input.isHeld(keyW))
