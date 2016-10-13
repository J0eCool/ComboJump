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
  gun,
  util,
  vec

proc findNearestTarget(entities: seq[Entity], pos: Vec): Vec =
  var
    target = pos
    minDist = -1.0
  entities.forComponents e, [
    Transform, t,
    Health, h,
  ]:
    let dist = distance2(pos, t.pos)
    if minDist < 0.0 or dist < minDist:
      target = t.pos
      minDist = dist
  return target

proc updateHomingBullets(entities: seq[Entity], dt: float) =
  entities.forComponents e, [
    Bullet, b,
    HomingBullet, h,
    Movement, m,
    Transform, t,
  ]:
    if h.turnRate <= 0:
      h.turnRate = random(350.0, 500.0)
    let
      target = findNearestTarget(entities, t.pos)
      delta = target - t.pos 
      s = sign(m.vel.cross(delta)).float
      baseTurn = s * h.turnRate.degToRad * dt
      turn = lerp((1 - b.lifePct) * 5, 0, baseTurn)
    m.vel = m.vel.rotate(turn)

proc updateFieryBullets*(entities: seq[Entity], dt: float): seq[Event] =
  result = @[]
  entities.forComponents e, [
    FieryBullet, f,
    Movement, m,
    Transform, t,
  ]:
    f.timer += dt
    assert f.interval > 0
    while f.timer >= f.interval:
      f.timer -= f.interval
      let
        vel = m.vel.rotate(random(-PI/3, PI/3) - PI) * 0.15
        flare = newEntity("Flare", [
          Transform(
            pos: t.pos + randomVec(t.size.length),
            size: t.size * f.size,
          ),
          Sprite(color: color(255, 128, 32, 255)),
          Collider(),
          Movement(vel: vel),
          newBullet(damage=0, liveTime=f.liveTime),
        ])
      result.add Event(kind: addEntity, entity: flare)

proc updateBullets*(entities: seq[Entity], dt: float): Events =
  result = @[]
  entities.forComponents e, [
    Bullet, b,
    Collider, c,
    Movement, m,
  ]:
    b.timeLeft -= dt
    if b.timeLeft <= 0.0 or c.collisions.len > 0:
      result.add(Event(kind: removeEntity, entity: e))

      if b.nextStage != nil:
        e.withComponent Transform, t:
          result &= b.nextStage(t.pos, m.vel.unit)

  entities.updateHomingBullets dt
