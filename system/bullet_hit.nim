import
  component/bullet,
  component/collider,
  component/health,
  entity,
  util

proc updateBulletDamage*(entities: seq[Entity]): seq[Entity] =
  result = @[]
  forComponents(entities, e, [
    Collider, c,
    Health, h,
  ]):
    for other in c.collisions:
      other.withComponent Bullet, b:
        h.curHealth -= b.damage
        if h.curHealth <= 0:
          result.add(e)
          break
