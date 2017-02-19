import
  component/limited_quantity,
  entity,
  event,
  game_system,
  logging,
  notifications

type
  HealthObj* = object of LimitedQuantityObj
  Health* = ref HealthObj

defineComponent(Health, @[])

proc newHealth*(maxHealth: int): Health =
  new result
  result.init maxHealth

defineSystem:
  components = [Health]
  proc updateHealth*(notifications: var N10nManager) =
    if health.cur <= 0:
      log "Health", debug, "Entity died - ", entity
      result.add event.Event(kind: removeEntity, entity: entity)
      notifications.add N10n(kind: entityKilled, entity: entity)
