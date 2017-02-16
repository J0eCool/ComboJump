import
  component/limited_quantity,
  entity

type Mana* = ref object of LimitedQuantity

defineComponent(Mana)

proc newMana*(maxMana: int): Mana =
  new result
  result.init maxMana
  result.regenPerSecond = 10

proc trySpend*(m: Mana, cost: float): bool =
  if m.cur >= cost:
    m.cur -= cost
    return true
  return false
