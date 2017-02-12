import unittest

import
  util

suite "Util":
  test "remove":
    var list = @[1, 2, 4, 5, 7, 8, 10]
    list.remove(4)
    check list == @[1, 2, 5, 7, 8, 10]
    list.remove(1)
    check list == @[2, 5, 7, 8, 10]
    list.remove(5)
    list.remove(7)
    check list == @[2, 8, 10]
