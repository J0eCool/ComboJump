import
  rpg_frontier/[
    damage,
    element,
    percent,
  ],
  color

type
  Ailments* = ElementSet[AilmentState]
  AilmentState* = object
    progress*: int
    capacity*: int
    stacks*: int

proc newAilments*(): Ailments =
  result = newElementSet[AilmentState]()
  for e in Element:
    result[e].capacity = 100

proc percent*(state: AilmentState): float =
  state.progress / state.capacity

proc stacks*(ailments: Ailments, element: Element): int =
  ailments[element].stacks
proc progress*(ailments: Ailments, element: Element): int =
  ailments[element].progress
proc percent*(ailments: Ailments, element: Element): float =
  ailments[element].percent

proc takeDamage*(ailments: var Ailments, damage: Damage) =
  let total = damage.total()
  if damage.ailment == 0 or total == 0:
    return
  for element in Element:
    template cur: AilmentState = ailments[element]
    cur.progress += damage.ailment * damage.amounts[element] div total
    while cur.progress >= cur.capacity:
      cur.progress -= cur.capacity
      cur.stacks += 1

proc ailmentName*(element: Element): string =
  case element
  of physical:
    "Bleed"
  of fire:
    "Burn"
  of ice:
    "Chill"

proc ailmentColor*(element: Element): Color =
  case element
  of physical:
    darkRed
  of fire:
    orange
  of ice:
    lightBlue

proc bleedDamage*(ailments: Ailments): Damage =
  let stacks = ailments.stacks(physical)
  singleDamage(physical, 2 * stacks)

proc burnDamage*(ailments: Ailments): Damage =
  let stacks = ailments.stacks(fire)
  singleDamage(fire, 2 * stacks)

proc chillEffect*(ailments: Ailments): Percent =
  let stacks = ailments.stacks(ice)
  Percent(50 * stacks)
