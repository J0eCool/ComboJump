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
  color,
  entity,
  event,
  game_system,
  vec,
  util

type
  CaveEnemyShooterObj* = object of ComponentObj
    shotOffset*: Vec
    fireRate*: float
    shotTimer: float
  CaveEnemyShooter* = ref CaveEnemyShooterObj

defineComponent(CaveEnemyShooter, @[])

proc spawnBullet(pos, vel: Vec): Entity =
  newEntity("Bullet", [
    Damage(damage: 1),
    Bullet(liveTime: 3.0),
    Collider(
      layer: Layer.enemyBullet,
      ignoreFloor: true,
    ),
    Transform(
      pos: pos,
      size: vec(48),
    ),
    Movement(
      vel: vel,
      usesGravity: true,
    ),
    Sprite(color: orange),
    RemoveWhenOffscreen(),
  ])

defineSystem:
  components = [CaveEnemyShooter, Movement, Transform]
  proc updateCaveEnemyShooter*(dt: float) =
    let
      shoot = caveEnemyShooter
      cooldown = 1.0 / shoot.fireRate
    shoot.shotTimer += dt
    if shoot.shotTimer >= cooldown:
      shoot.shotTimer -= cooldown
      let
        pos = transform.pos + shoot.shotOffset
        vel = vec(400.0 * movement.vel.x.sign.float, -600.0) + randomVec(20.0)
      result.add Event(kind: addEntity, entity: spawnBullet(pos, vel))
      