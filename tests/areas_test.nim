import unittest

import
  areas,
  enemy_kind,
  util

suite "AreaInfo":
  let testArea = AreaInfo(
    name: "TestArea",
    keyStages: @[
      StageDesc(
        stage: 1,
        rooms: 4,
        sidePaths: 1,
        level: 1,
        enemiesPerRoom: 6,
        spawns: @[(goblin, 1.0)]
      ),
      StageDesc(
        stage: 3,
        rooms: 6,
        sidePaths: 0,
        level: 5,
        enemiesPerRoom: 12,
        spawns: @[(goblin, 2.0), (ogre, 1.0)]
      ),
      StageDesc(
        stage: 5,
        rooms: 4,
        sidePaths: 2,
        level: 3,
        enemiesPerRoom: 24,
        spawns: @[(goblin, 2.0)]
      ),
    ],
  )

  test "Get first key stage":
    let stage = testArea.stageDesc(1)
    check:
      stage.rooms == 4
      stage.sidePaths == 1
      stage.level == 1
      stage.enemiesPerRoom == 6
      stage.spawns == @[(goblin, 1.0)]

  test "Get last key stage":
    let stage = testArea.stageDesc(5)
    check:
      stage.rooms == 4
      stage.sidePaths == 2
      stage.level == 3
      stage.enemiesPerRoom == 24
      stage.spawns == @[(goblin, 2.0)]

  test "Lerping stages":
    let stage = testArea.stageDesc(2)
    check:
      stage.rooms == 5
      stage.sidePaths == 1
      stage.level == 3
      stage.enemiesPerRoom == 9
      stage.spawns == @[(goblin, 1.5), (ogre, 0.5)]

  test "Lerping other stages":
    let stage = testArea.stageDesc(4)
    check:
      stage.rooms == 5
      stage.sidePaths == 1
      stage.level == 4
      stage.enemiesPerRoom == 18
      stage.spawns == @[(goblin, 2.0), (ogre, 0.5)]
