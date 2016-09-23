import
  component,
  util

type Health* = ref object of Component
  max*, cur*: int

proc newHealth*(maxHealth: int): Health =
  new result
  result.max = maxHealth
  result.cur = maxHealth
