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
  jsonparse,
  vec,
  util

type
  CaveWeapon = object
    fireRate*: float
    cooldown: float
  CavePlayerShooterObj* = object of ComponentObj
    shotOffset*: Vec
    weapon*: CaveWeapon
    weapon2*: CaveWeapon
  CavePlayerShooter* = ref CavePlayerShooterObj

autoObjectJsonProcs(CaveWeapon)
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
  proc updateCavePlayerShooter*(dt: float, input: InputManager) =
    let shoot = cavePlayerShooter
    proc update(weapon: var CaveWeapon, key: Input): Events =
      result = @[]
      weapon.cooldown -= dt
      if input.isHeld(key) and weapon.cooldown <= 0.0:
        weapon.cooldown = 1.0 / weapon.fireRate
        let
          pos = transform.pos + shoot.shotOffset
          vel = vec(1000.0 * platformerControl.facingSign, 0.0) + randomVec(20.0)
        result.add Event(kind: addEntity, entity: spawnBullet(pos, vel))
    result &= shoot.weapon.update(keyJ)
    result &= shoot.weapon2.update(keyI)
