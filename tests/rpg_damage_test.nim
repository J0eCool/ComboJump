import unittest

import
  rpg_frontier/[
    damage,
    element,
    percent,
  ]

suite "Damage":
  test "ElementSets initialize properly":
    let elements = newElementSet[int]()
      .init(fire, 12)
      .init(ice, 3)
    check:
      elements[physical] == 0
      elements[fire] == 12
      elements[ice] == 3

  test "Damage total sums properly":
    let damage = Damage(
      amounts: newElementSet[int]()
        .init(fire, 12)
        .init(ice, 3),
    )
    check damage.total() == 15

  test "Elemental resistance is applied":
    let
      damage = singleDamage(fire, 10)
      defense = singleResist(fire, 50.Percent)
      reduced = damage.apply(defense)
    check:
      reduced.total() == 5
      reduced.amounts[fire] == 5

  test "Elemental weakness is applied":
    let
      damage = singleDamage(fire, 10)
      defense = singleResist(fire, -50.Percent)
      reduced = damage.apply(defense)
    check:
      reduced.total() == 15
      reduced.amounts[fire] == 15

  test "Ailment damage is preserved when applying resistance":
    let
      damage = singleDamage(fire, 10, 10)
      defense = singleResist(fire, 50.Percent)
      reduced = damage.apply(defense)
    check reduced.ailment == 10
