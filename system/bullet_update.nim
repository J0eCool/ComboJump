import
  component/bullet,
  entity

proc updateBullets*(entities: var seq[Entity], dt: float) =
  var toRemove: seq[Entity] = @[]
  forComponents(entities, e, [
    Bullet, b,
  ]):
    b.liveTime -= dt
    if b.liveTime <= 0.0:
      toRemove.add(e)
  for e in toRemove:
    entities.del(entities.find(e))