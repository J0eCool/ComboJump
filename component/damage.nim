import
  component/collider,
  component/health,
  entity,
  event,
  notifications,
  system,
  util,
  vec

type
  Damage* = ref object of Component
    damage*: int

defineSystem:
  components = [Health, Collider]
  proc updateDamage*(notifications: var N10nManager) =
    for col in collider.collisions:
      col.withComponent Damage, damage:
        health.cur -= damage.damage.float
        collider.collisionBlacklist.add col
        if health.cur <= 0:
          result.add Event(kind: removeEntity, entity: entity)
          notifications.add N10n(kind: entityKilled, entity: entity)
          break
