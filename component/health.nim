import
  component,
  util

type Health* = ref object of Component
  max*, cur*: int

proc newHealth*(maxHealth: int): Health =
  new result
  result.max = maxHealth
  result.cur = maxHealth

proc pct*(health: Health): float =
  clamp(health.cur.float / health.max.float, 0, 1)
