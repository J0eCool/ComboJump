import math
from sdl2 import color

import
  component/[
    bullet,
    collider,
    health,
    limited_time,
    movement,
    particle_effect,
    sprite,
    transform,
  ],
  color,
  entity,
  event,
  game_system,
  notifications,
  util,
  vec

defineSystem:
  components = [Bullet, Collider, Transform]
  proc updateBullets*(dt: float) =
    bullet.timeSinceSpawn += dt
    if bullet.onUpdate != nil:
      bullet.onUpdate(entity, dt)
      
    if bullet.lifePct <= 0.0 or (collider.collisions.len > 0 and not bullet.stayOnHit):
      result.add(Event(kind: removeEntity, entity: entity))
      result.add(Event(kind: addEntity, entity: newEntity("Particles", [
        Transform(pos: transform.pos),
        ParticleEffect(
          color: yellow,
        ),
        LimitedTime(limit: 0.1),
      ])))

defineSystem:
  components = [RepeatShooter, Transform]
  proc updateRepeatShooter*(dt: float) =
    repeatShooter.shootCooldown -= dt
    if repeatShooter.shootCooldown < 0.0:
      result &= repeatShooter.toShoot(transform.pos, repeatShooter.dir)
      repeatShooter.shootCooldown += 0.35
      repeatShooter.numToRepeat -= 1
      if repeatShooter.numToRepeat <= 0:
        result.add Event(kind: removeEntity, entity: entity)

defineSystem:
  proc updateBulletN10ns*(notifications: N10nManager) =
    result = @[]
    for n10n in notifications.get(entityRemoved):
      let entity = n10n.entity
      entity.withComponent Transform, transform:
        entity.withComponent Bullet, bullet:
          if bullet.nextStage != nil:
            result &= bullet.nextStage(transform.pos, bullet.dir)

        entity.withComponent RepeatShooter, repeatShooter:
          if repeatShooter.nextStage != nil:
            result &= repeatShooter.nextStage(transform.pos, repeatShooter.dir)
