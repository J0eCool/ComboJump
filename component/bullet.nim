import math
import
  component/component,
  component/collider,
  component/health,
  component/movement,
  component/transform,
  entity,
  util,
  vec

type Bullet* = ref object of Component
  damage*: int
  liveTime*: float
  timeLeft*: float

proc newBullet*(damage: int, liveTime: float): Bullet =
  Bullet(
    damage: damage,
    liveTime: liveTime,
    timeLeft: liveTime,
  )

proc lifePct*(b: Bullet): float =
  b.timeLeft / b.liveTime

type HomingBullet* = ref object of Component
  turnRate*: float

############################################################

proc findNearestTarget(entities: seq[Entity], pos: Vec): Vec =
  var
    target = pos
    maxDist = 0.0
  forComponents(entities, e, [
    Transform, t,
    Health, h,
  ]):
    let dist = distance2(pos, t.pos)
    if dist > maxDist:
      target = t.pos
      maxDist = dist
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

proc updateBullets*(entities: seq[Entity], dt: float): seq[Entity] =
  result = @[]
  forComponents(entities, e, [
    Bullet, b,
    Collider, c,
    Movement, m,
  ]):
    b.timeLeft -= dt
    if b.timeLeft <= 0.0 or c.collisions.len > 0:
      result.add(e)

  entities.updateHomingBullets dt
