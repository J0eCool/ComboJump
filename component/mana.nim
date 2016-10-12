import component/limited_quantity

type Mana* = ref object of LimitedQuantity

proc newMana*(maxMana: int): Mana =
  new result
  result.init maxMana
  result.regenPerSecond = 10

proc trySpend*(m: Mana, cost: float): bool =
  if m.cur >= cost:
    m.cur -= cost
    return true
  return false
