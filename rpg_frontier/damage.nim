import
  rpg_frontier/[
    element,
    percent,
  ]

type
  Damage* = object
    amounts*: ElementSet[int]
    ailment*: int
  Defense* = object
    resistances*: ElementSet[Percent]
    armor*: int

proc total*(damage: Damage): int =
  for val in damage.amounts:
    result += val

proc apply*(damage: Damage, defense: Defense): Damage =
  var reduced = newElementSet[int]()
  for e in Element:
    reduced[e] = damage.amounts[e] - defense.resistances[e]
  Damage(
    amounts: reduced,
    ailment: damage.ailment,
  )

proc singleDamage*(element: Element, damage: int, ailment = 0): Damage =
  Damage(
    amounts: newElementSet[int]().init(element, damage),
    ailment: ailment,
  )

proc singleResist*(element: Element, resist: Percent): Defense =
  Defense(resistances: newElementSet[Percent]().init(element, resist))
