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
        up: Door(kind: doorOpen, room: 2),
        kind: roomStart,
      )
      r2 = Room(
        id: 2,
        down: Door(kind: doorOpen, room: 1),
        kind: roomEnd,
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
        up: Door(kind: doorOpen, room: 2),
        kind: roomStart,
      )
      r2 = Room(
        id: 2,
        down: Door(kind: doorOpen, room: 1),
      )
      r3 = Room(
        id: 3,
        kind: roomEnd,
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
        up: Door(kind: doorOpen, room: 2),
        right: Door(kind: doorOpen, room: 3),
        kind: roomStart,
      )
      r2 = Room(
        id: 2,
        down: Door(kind: doorOpen, room: 1),
      )
      r3 = Room(
        id: 3,
        left: Door(kind: doorOpen, room: 1),
        up: Door(kind: doorOpen, room: 4),
      )
      r4 = Room(
        id: 4,
        down: Door(kind: doorOpen, room: 3),
        kind: roomEnd,
      )
      map = Map(
        rooms: @[r1, r2, r3, r4],
      )
      solution = solve(map)
    check:
      solution.pathExists
      solution.length == 3
