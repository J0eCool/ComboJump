import component

type Mana* = ref object of Component
  max*, cur*: int
  partial*: float

proc newMana*(maxMana: int): Mana =
  new result
  result.max = maxMana
  result.cur = maxMana
  result.partial = 0

proc pct*(mana: Mana): float =
  clamp(mana.cur.float / mana.max.float, 0, 1)
