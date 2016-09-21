import
  component/bullet,
  component/collider,
  component/health,
  component/movement,
  entity,
  util,
  vec

proc updateBullets*(entities: var seq[Entity], dt: float) =
  var toRemove: seq[Entity] = @[]
  forComponents(entities, e, [
    Bullet, b,
    Collider, c,
    Movement, m,
  ]):
    m.vel = b.vel
    b.timeLeft -= dt
    if b.timeLeft <= 0.0 or c.collisions.len > 0:
      toRemove.add(e)
    if b.isSpecial:
      m.vel = b.vel * (b.timeLeft / b.liveTime)
  for e in toRemove:
    entities.remove(e)
