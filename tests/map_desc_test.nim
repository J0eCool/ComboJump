import unittest

import
  nano_mapgen/[
    map,
    map_desc,
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
