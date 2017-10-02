import unittest

import
  quick_shoot/[
    level,
  ],
  util,
  vec

suite "Levels - Spawns":
  proc testSpawn(start, interval: float, count: int): SpawnData =
    (start, interval, count, goblinUp, vec())
  proc testLevel(start, interval: float, count: int): Level =
    Level(spawns: @[testSpawn(start, interval, count)])

  test "No spawns before start":
    check testLevel(1.0, 2.0, 1).toSpawn(0.0, 0.5).len == 0

  test "No spawns after end":
    check testLevel(1.0, 2.0, 1).toSpawn(3.0, 3.5).len == 0

  test "No spawns between multiple spawn windows times":
    let level = Level(
      spawns: @[
        (1.0, 0.0, 1, goblinUp, vec()),
        (3.0, 5.0, 1, goblinUp, vec()),
      ],
    )
    check level.toSpawn(2.0, 2.5).len == 0

  test "Single spawns use only the start time":
    check testSpawn(1.0, 0.0, 1).spawnTimes.approxEq(@[1.0])

  test "Two spawns use start and end times":
    check testSpawn(1.0, 1.0, 2).spawnTimes.approxEq(@[1.0, 2.0])

  test "More spawns spread the time out":
    check testSpawn(1.0, 0.25, 5).spawnTimes.approxEq(@[1.0, 1.25, 1.5, 1.75, 2.0])

  test "Spawn happens between bounds":
    check testLevel(1.0, 2.0, 1).toSpawn(0.9, 1.1).len == 1

  test "Spawn happens on end bound":
    check testLevel(1.0, 2.0, 1).toSpawn(0.9, 1.0).len == 1

  test "Spawn does not happen on start bound":
    check testLevel(1.0, 2.0, 1).toSpawn(1.0, 1.1).len == 0

  test "Spawning half of a group":
    check testLevel(1.0, 0.25, 5).toSpawn(0.9, 1.5).len == 3
