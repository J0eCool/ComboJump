import
  component/collider,
  component/health,
  entity,
  event,
  system,
  util,
  vec

type
  Damage* = ref object of Component
    damage*: int

defineSystem:
  proc updateDamage*() =
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
