import math
from sdl2 import color

import
  component/bullet,
  component/collider,
  component/health,
  component/movement,
  component/transform,
  component/sprite,
  entity,
  event,
  game_system,
  notifications,
  util,
  vec

defineSystem:
  proc updateBullets*(dt: float) =
    result = @[]
    entities.forComponents e, [
      Bullet, b,
      Collider, c,
    ]:
      b.timeSinceSpawn += dt
      if b.onUpdate != nil:
        b.onUpdate(e, dt)
        
      if b.lifePct <= 0.0 or (c.collisions.len > 0 and not b.stayOnHit):
        result.add(Event(kind: removeEntity, entity: e))

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
