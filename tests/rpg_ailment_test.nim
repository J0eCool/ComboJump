import unittest

import
  rpg_frontier/[
    ailment,
    damage,
    element,
    percent,
  ]

{.push hint[XDeclaredButNotUsed]: off.}
suite "Ailments":
  setup:
    var ailments = newAilments()
    let
      smallPhysDamage = singleDamage(physical, 10, 50)
      largePhysDamage = singleDamage(physical, 10, 150)
      hugePhysDamage = singleDamage(physical, 10, 1000)
      smallFireDamage = singleDamage(fire, 5, 50)
      mixedDamage = Damage(
        amounts: newElementSet[int]()
          .init(physical, 15)
          .init(fire, 5),
        ailment: 100,
      )

    proc checkStatus(element: Element, expectedStacks, expectedProgress: int) =
      check:
        ailments.stacks(element) == expectedStacks
        ailments.progress(element) == expectedProgress

  test "Ailments start with no stacks and no progress":
    checkStatus(physical, 0, 0)

  test "Taking small damage gives ailment progress":
    ailments.takeDamage(smallPhysDamage)
    checkStatus(physical, 0, 50)

  test "Taking large damage gives stacks":
    ailments.takeDamage(largePhysDamage)
    checkStatus(physical, 1, 50)

  test "Taking repeated small damage is the same as large damage":
    ailments.takeDamage(smallPhysDamage)
    ailments.takeDamage(smallPhysDamage)
    ailments.takeDamage(smallPhysDamage)
    checkStatus(physical, 1, 50)

  test "Taking huge damage gives multiple stacks":
    ailments.takeDamage(hugePhysDamage)
    checkStatus(physical, 10, 0)

  test "Taking non-physical damage gives non-physical ailments":
    ailments.takeDamage(smallFireDamage)
    checkStatus(physical, 0, 0)
    checkStatus(fire, 0, 50)

  test "Mixed damage gives multiple ailments, proportional to damage dealt":
    ailments.takeDamage(mixedDamage)
    checkStatus(physical, 0, 75)
    checkStatus(fire, 0, 25)

{.pop.} # hint[XDeclaredButNotUsed]: off
