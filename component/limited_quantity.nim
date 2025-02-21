import entity

type
  LimitedQuantityObj* = object of ComponentObj
    max*: float
    cur*: float
    regenPerSecond*: float
    held*: float
  LimitedQuantity* = ref LimitedQuantityObj

defineComponent(LimitedQuantity, @[])

proc init*(limited: LimitedQuantity, max: int) =
  limited.max = max.float
  limited.cur = max.float

proc pct*(limited: LimitedQuantity): float =
  clamp(limited.cur / limited.max, 0, 1)
proc heldPct*(limited: LimitedQuantity): float =
  clamp(limited.held / limited.max, 0, 1)

template regen*(limited: LimitedQuantity, dt: float) =
  limited.cur += limited.regenPerSecond * dt
  limited.cur = min(limited.cur, limited.max)
