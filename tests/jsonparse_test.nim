import
  tables,
  unittest

import
  jsonparse

type TestEnum = enum
  one
  two

type TestObject = object
  intVal: int
  strVal: string
  enumVal: TestEnum
  arrayVal: seq[int]

template testRoundtrip(name: string, ty, value, jsonString: untyped): untyped =
  test ($name & " toJSON"):
    check $toJSON(value) == jsonString

  test ($name & " fromJSON"):
    check fromJSON[ty](deserializeJSON(jsonString)) == value

suite "JSON parsing":
  testRoundtrip(
    "Int", int,
    127,
    "\"127\""
  )

  testRoundtrip(
    "Negative Int", int,
    -7,
    "\"-7\""
  )

  testRoundtrip(
    "String", string,
    "String literal.",
    "\"String literal.\""
  )

  testRoundtrip(
    "Enum", TestEnum,
    one,
    "\"one\""
  )

  testRoundtrip(
    "Array", seq[int],
    @[8, 0, 2, 3],
    """["8","0","2","3"]"""
  )

  testRoundtrip(
    "Nested array", seq[seq[int]],
    @[@[1, 2], @[3, 4]],
    """[["1","2"],["3","4"]]"""
  )

  var testTable = initTable[string, int]()
  testTable["foo"] = 12
  testTable["Bar"] = 101
  testRoundtrip(
    "Tables", Table[string, int],
    testTable,
    """{"Bar":"101","foo":"12"}"""
  )

  testRoundtrip(
    "Objects", TestObject,
    TestObject(
      intVal: 37,
      strVal: "test string",
      enumVal: two,
      arrayVal: @[6, 0, 2],
    ),
    """{"arrayVal":["6","0","2"],"enumVal":"two","intVal":"37","strVal":"test string"}"""
  )

  test "Whitespace is ignored when reading JSON":
    check fromJSON[seq[int]](deserializeJSON(" [\"1\", \"2\",\n \"3\" ] ")) == @[1, 2, 3]

# TODO: have non-aborting fromJSON failures
  # echo "fails: ", fromJSON[TestEnum](JSON(kind: jsString, str: "three"))
