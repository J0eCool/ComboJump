import unittest

import
  nano_mapgen/map

suite "Map":
  test "Simple map":
    let
      # TODO: workaround for https://github.com/nim-lang/Nim/issues/5339
      room1 = Room(
        id: 1,
        up: 2,
        kind: roomStart,
      )
      room2 = Room(
        id: 2,
        down: 1,
        kind: roomEnd,
      )
      map = Map(
        rooms: @[room1, room2],
      )
      solution = solve(map)
    check:
      solution.pathExists
      solution.length == 2

  test "No path":
    let
      room1 = Room(
        id: 1,
        up: 2,
        kind: roomStart,
      )
      room2 = Room(
        id: 2,
        down: 1,
      )
      room3 = Room(
        id: 3,
        kind: roomEnd,
      )
      map = Map(
        rooms: @[room1, room2, room3],
      )
      solution = solve(map)
    check(not solution.pathExists)
