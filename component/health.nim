import
  component/limited_quantity,
  entity,
  event,
  game_system,
  notifications

type Health* = ref object of LimitedQuantity

proc newHealth*(maxHealth: int): Health =
  new result
  result.init maxHealth

defineSystem:
  components = [Health]
  proc updateHealth*(notifications: var N10nManager) =
    if health.cur <= 0:
      result.add event.Event(kind: removeEntity, entity: entity)
      notifications.add N10n(kind: entityKilled, entity: entity)
