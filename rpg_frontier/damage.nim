import
  rpg_frontier/[
    percent,
  ]

type
  Element* = enum
    physical
    fire
    ice
  ElementSet*[T] = array[Element, T]
  Damage* = object
    amounts*: ElementSet[int]
  Defense* = object
    armor*: int
    resistances*: ElementSet[Percent]

proc newElementSet*[T](): ElementSet[T] =
  discard

proc init*[T](elements: ElementSet[T], element: Element, val: T): ElementSet[T] =
  result = elements
  result[element] = val

proc total*(damage: Damage): int =
  for val in damage.amounts:
    result += val

proc apply*(damage: Damage, defense: Defense): Damage =
  var reduced = newElementSet[int]()
  for e in Element:
    reduced[e] = damage.amounts[e] - defense.resistances[e]
  Damage(amounts: reduced)
