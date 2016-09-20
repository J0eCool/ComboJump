import
  component,
  util

type Health* = ref object of Component
  maxHealth*, curHealth*: int

proc newHealth*(maxHealth: int): Health =
  new result
  result.maxHealth = maxHealth
  result.curHealth = maxHealth
