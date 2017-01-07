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
  system,
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

        if b.nextStage != nil:
          e.withComponent Transform, t:
            result &= b.nextStage(t.pos, b.dir)
