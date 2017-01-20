import unittest

import
  jsonparse

type TestEnum = enum
  one
  two

template roundtrip(name: string, ty, value, jsonString: untyped): untyped =
  test ($name & " toJSON"):
    check $toJSON(value) == jsonString

  test ($name & " fromJSON"):
    check fromJSON[ty](deserializeJSON(jsonString)) == value

suite "JSON parsing":
  roundtrip("Int", int, 127, "\"127\"")
  roundtrip("Negative Int", int, -7, "\"-7\"")
  roundtrip("String", string, "String literal.", "\"String literal.\"")
  roundtrip("Enum", TestEnum, one, "\"one\"")
  roundtrip("Seq", seq[int], @[8, 0, 2, 3], """["8","0","2","3"]""")

  # TODO: dicts, objects
  # TODO: check skipping whitespace, pretty-printing

# TODO: have non-aborting fromJSON failures
  # echo "fails: ", fromJSON[TestEnum](JSON(kind: jsString, str: "three"))
