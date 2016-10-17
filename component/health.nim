import component/limited_quantity, entity

type Health* = ref object of LimitedQuantity
genComponentType(Health)

proc newHealth*(maxHealth: int): Health =
  new result
  result.init maxHealth
