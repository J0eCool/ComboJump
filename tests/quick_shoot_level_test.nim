import unittest

import
  component/[
    enemy_shooter_movement,
  ],
  quick_shoot/[
    level,
  ],
  util,
  vec

suite "Levels - Spawns":
  proc testSpawn(delay: float, interval = 0.0, count = 1): SpawnData =
    (delay, interval, count, goblin, straight(vec(), 0.0), spawnOnRight(0.0))
  proc testLevel(delay: float, interval = 0.0, count = 1): Level =
    Level(spawns: @[testSpawn(delay, interval, count)])

  let multiLevel = Level(
    spawns: @[
      testSpawn(1.0),
      testSpawn(2.0),
    ],
  )

  test "No spawns before start":
    check testLevel(1.0, 2.0).toSpawn(0.0, 0.5).len == 0

  test "No spawns after end":
    check testLevel(1.0, 2.0).toSpawn(3.0, 3.5).len == 0

  test "No spawns between multiple spawn windows times":
    check multiLevel.toSpawn(1.5, 2.5).len == 0

  test "Second spawn in multiple windows is delayed by first":
    check multiLevel.toSpawn(2.5, 3.5).len == 1

  test "Single spawns use only the start time":
    check testSpawn(1.0).spawnTimes.approxEq(@[1.0])

  test "Two spawns use start and end times":
    check testSpawn(1.0, 1.0, 2).spawnTimes.approxEq(@[1.0, 2.0])

  test "More spawns spread the time out":
    check testSpawn(1.0, 0.25, 5).spawnTimes.approxEq(@[1.0, 1.25, 1.5, 1.75, 2.0])

  test "Spawn happens between bounds":
    check testLevel(1.0).toSpawn(0.9, 1.1).len == 1

  test "Spawn happens on end bound":
    check testLevel(1.0).toSpawn(0.9, 1.0).len == 1

  test "Spawn does not happen on start bound":
    check testLevel(1.0).toSpawn(1.0, 1.1).len == 0

  test "Spawning half of a group":
    check testLevel(1.0, 0.25, 5).toSpawn(0.9, 1.5).len == 3

  test "Spawning is not done when just starting":
    check testLevel(1.0, 0.25, 2).isDoneSpawning(0.0) == false

  test "Spawning is not done when still spawning":
    check testLevel(1.0, 0.25, 2).isDoneSpawning(1.1) == false

  test "Spawning is done when done":
    check testLevel(1.0, 0.25, 2).isDoneSpawning(1.6) == true

  test "Spawning is not done when not all spawns are done":
    check multiLevel.isDoneSpawning(1.5) == false

  test "Spawning is done when all spawns are done":
    check multiLevel.isDoneSpawning(3.5) == true

  test "Spawning is done after last spawn even if it doesn't start last":
    let level = Level(
      spawns: @[
        testSpawn(1.0),
        testSpawn(1.0, 0.5, 5),
        testSpawn(1.0),
      ],
    )
    check:
      level.isDoneSpawning(3.5) == false
      level.isDoneSpawning(4.6) == true
