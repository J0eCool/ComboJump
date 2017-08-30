import
  rpg_frontier/[
    damage,
    element,
  ]

type
  Ailments* = ElementSet[AilmentState]
  AilmentState* = object
    progress*: int
    capacity*: int
    stacks: int

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
  ailments[physical].progress += damage.ailment
  while ailments[physical].progress > ailments[physical].capacity:
    ailments[physical].progress -= ailments[physical].capacity
    ailments[physical].stacks += 1
