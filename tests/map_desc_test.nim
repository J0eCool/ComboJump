import unittest

import
  nano_mapgen/[
    map,
    map_desc,
    map_solver,
    room,
  ]

suite "MapDesc":
  test "Straight line":
    let
      desc = MapDesc(length: 5)
      map = desc.generate()
      solution = map.solve()
    check:
      solution.pathExists
      solution.length == 5

  test "Forks":
    let
      desc = MapDesc(length: 5, numSidePaths: 2)
      map = desc.generate()
      solution = map.solve()
    check:
      solution.pathExists
      solution.length >= 5
      map.rooms.len >= 7
