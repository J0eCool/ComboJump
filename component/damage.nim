import
  component/collider,
  component/health,
  entity,
  event,
  util,
  vec

type
  Damage* = ref object of Component
    damage*: int

proc updateDamage*(entities: Entities): Events =
  result = @[]
  entities.forComponents e, [
    Health, h,
    Collider, c,
  ]:
    for col in c.collisions:
      col.withComponent Damage, d:
        h.cur -= d.damage.float
        if h.cur <= 0:
          result.add Event(kind: removeEntity, entity: e)
          break
