import unittest

import
  rpg_frontier/[
    ailment,
    damage,
    element,
    percent,
  ]

suite "Ailments":
  setup:
    var ailments = newAilments()
    let
      smallPhysDamage = singleDamage(physical, 10, 50)
      largePhysDamage = singleDamage(physical, 10, 150)

    proc checkStatus(element: Element, stacks, progress: int) =
      check:
        ailments.stacks(element) == stacks
        ailments.progress(element) == progress

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
