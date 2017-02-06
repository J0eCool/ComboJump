import unittest

import
  nano_mapgen/[
    map,
    map_solver,
    room,
  ]

suite "Map":
  test "Simple map":
    let
      # TODO: workaround for https://github.com/nim-lang/Nim/issues/5339
      r1 = Room(
        id: 1,
        kind: roomStart,
        x: 0, y: 0,
        up: doorOpen,
      )
      r2 = Room(
        id: 2,
        kind: roomEnd,
        x: 0, y: 1,
        down: doorOpen,
      )
      map = Map(
        rooms: @[r1, r2],
      )
      solution = solve(map)
    check:
      solution.pathExists
      solution.length == 2

  test "No path":
    let
      r1 = Room(
        id: 1,
        kind: roomStart,
        x: 0, y: 0,
        up: doorOpen,
      )
      r2 = Room(
        id: 2,
        x: 0, y: 1,
        down: doorOpen,
      )
      r3 = Room(
        id: 3,
        kind: roomEnd,
        x: 2, y: 2,
      )
      map = Map(
        rooms: @[r1, r2, r3],
      )
      solution = solve(map)
    check(not solution.pathExists)

  test "Handles dead ends":
    let
      r1 = Room(
        id: 1,
        kind: roomStart,
        x: 0, y: 0,
        up: doorOpen,
        right: doorOpen,
      )
      r2 = Room(
        id: 2,
        x: 0, y: 1,
        down: doorOpen,
      )
      r3 = Room(
        id: 3,
        x: 1, y: 0,
        left: doorOpen,
        up: doorOpen,
      )
      r4 = Room(
        id: 4,
        kind: roomEnd,
        x: 1, y: 1,
        down: doorOpen,
      )
      map = Map(
        rooms: @[r1, r2, r3, r4],
      )
      solution = solve(map)
    check:
      solution.pathExists
      solution.length == 3
