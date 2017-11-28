import
  entity,
  event,
  game_system

type
  LimitedTimeObj* = object of ComponentObj
    limit*: float
    timer: float
  LimitedTime* = ref LimitedTimeObj

defineComponent(LimitedTime, @[
  "timer",
])

proc pct*(limited: LimitedTime): float =
  result = limited.timer / limited.limit

defineSystem:
  components = [LimitedTime]
  proc updateLimitedTime*(dt: float) =
    limitedTime.timer += dt
    if limitedTime.timer >= limitedTime.limit:
      result.add event.Event(kind: removeEntity, entity: entity)
