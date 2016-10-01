import
  component/bullet,
  component/collider,
  component/health,
  entity,
  event,
  util

proc updateBulletDamage*(entities: seq[Entity]): seq[Event] =
  result = @[]
  forComponents(entities, e, [
    Collider, c,
    Health, h,
  ]):
    for other in c.collisions:
      other.withComponent Bullet, b:
        h.cur -= b.damage.float
        if h.cur <= 0:
          result.add Event(kind: removeEntity, entity: e)
          break
