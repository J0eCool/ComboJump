import
  component/bullet,
  component/collider,
  component/health,
  component/movement,
  component/transform,
  entity,
  util,
  vec

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

proc updateBullets*(entities: var seq[Entity], dt: float): seq[Entity] =
  result = @[]
  forComponents(entities, e, [
    Bullet, b,
    Collider, c,
    Movement, m,
    Transform, t,
  ]):
    e.withComponent HomingBullet, h:
      let
        target = findNearestTarget(entities, t.pos)
        delta = target - t.pos 
        s = sign(b.vel.cross(delta)).float
        baseTurn = s * h.turnRate * dt
        turn = lerp((1 - b.lifePct) * 5, 0, baseTurn)
      b.vel = b.vel.rotate(turn)
    m.vel = b.vel
    b.timeLeft -= dt
    if b.timeLeft <= 0.0 or c.collisions.len > 0:
      result.add(e)
    if b.isSpecial:
      m.vel = b.vel * b.lifePct
