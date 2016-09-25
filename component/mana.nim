import component/limited_quantity

type Mana* = ref object of LimitedQuantity

proc newMana*(maxMana: int): Mana =
  new result
  result.init maxMana
  result.regenPerSecond = 10
