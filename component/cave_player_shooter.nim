import math

import
  component/[
    bullet,
    collider,
    damage_component,
    movement,
    platformer_control,
    remove_when_offscreen,
    sprite,
    transform,
  ],
  color,
  entity,
  event,
  game_system,
  input,
  screen_shake,
  vec,
  util

type
  CavePlayerShooterObj* = object of ComponentObj
    shotOffset*: Vec
    fireRate*: float
    cooldown: float
  CavePlayerShooter* = ref CavePlayerShooterObj

defineComponent(CavePlayerShooter, @[])

proc spawnBullet(pos, vel: Vec): Entity =
  newEntity("Bullet", [
    Damage(damage: 1),
    Bullet(liveTime: 3.0),
    Collider(layer: Layer.bullet),
    Transform(
      pos: pos,
      size: vec(32, 20),
    ),
    Movement(vel: vel),
    Sprite(color: yellow),
    RemoveWhenOffscreen(),
  ])

defineSystem:
  components = [CavePlayerShooter, PlatformerControl, Transform]
  proc updateCavePlayerShooter*(dt: float, input: InputManager, shake: var ScreenShake) =
    let shoot = cavePlayerShooter
    shoot.cooldown -= dt
    let shouldShoot = input.isHeld(keyJ) and shoot.cooldown <= 0.0
    if not shouldShoot:
      continue

    shoot.cooldown = 1.0 / shoot.fireRate
    let
      pos = transform.pos + shoot.shotOffset
      vel = vec(1000.0 * platformerControl.facingSign, 0.0) + randomVec(20.0)
    result.add Event(kind: addEntity, entity: spawnBullet(pos, vel))
    shake.start(5.0, 0.04)
