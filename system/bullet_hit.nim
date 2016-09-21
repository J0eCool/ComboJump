import
  component/bullet,
  component/collider,
  component/health,
  entity

proc updateBulletDamage*(entities: var seq[Entity]) =
  var toRemove: seq[Entity] = @[]
  forComponents(entities, e, [
    Collider, c,
    Health, h,
  ]):
    for other in c.collisions:
      other.withComponent Bullet, b:
        h.curHealth -= b.damage
        if h.curHealth <= 0:
          toRemove.add(e)
          break
  for e in toRemove:
    let idx = entities.find(e)
    if idx >= 0:
      entities.del(idx)
