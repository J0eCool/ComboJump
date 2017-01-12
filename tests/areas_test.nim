import unittest

import
  areas,
  enemy_kind,
  util

suite "AreaInfo":
  let testArea = AreaInfo(
    name: "TestArea",
    keyStages: @[
      StageDesc(stage: 1, length: 500, enemies: 6,
        spawns: @[(goblin, 1.0)]),
      StageDesc(stage: 3, length: 1000, enemies: 12,
        spawns: @[(goblin, 2.0), (ogre, 1.0)]),
      StageDesc(stage: 5, length: 1500, enemies: 24,
        spawns: @[(goblin, 2.0)]),
    ],
  )

  test "Get first key stage":
    let stage = testArea.stageDesc(1)
    check:
      stage.length.approxEq(500)
      stage.enemies == 6
      stage.spawns == @[(goblin, 1.0)]

  test "Get last key stage":
    let stage = testArea.stageDesc(5)
    check:
      stage.length.approxEq(1500)
      stage.enemies == 24
      stage.spawns == @[(goblin, 2.0)]

  test "Lerping stages":
    let stage = testArea.stageDesc(2)
    check:
      stage.length.approxEq(750)
      stage.enemies == 9
      stage.spawns == @[(goblin, 1.5), (ogre, 0.5)]

  test "Lerping other stages":
    let stage = testArea.stageDesc(4)
    check:
      stage.length.approxEq(1250)
      stage.enemies == 18
      stage.spawns == @[(goblin, 2.0), (ogre, 0.5)]
