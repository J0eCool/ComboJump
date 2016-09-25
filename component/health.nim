import component/limited_quantity

type Health* = ref object of LimitedQuantity

proc newHealth*(maxHealth: int): Health =
  new result
  result.init maxHealth
