import unittest

import
  color,
  input,
  menu,
  util

suite "Menus - Diffing":
  test "Wrong type gets replaced":
    var a = Node()
    let b = Button()
    a.diff(b)
    check a == b

suite "Menus - Button":
  test "Diff updates correctly":
    let
      procA = proc() =
        echo "In A"
      procB = proc() =
        echo "In B"
    var a = Button(
      label: "A",
      onClick: procA,
      hotkey: keyA,
      color: red,
      invisible: false,
    )
    let b = Button(
      label: "B",
      onClick: procB,
      hotkey: keyB,
      color: blue,
      invisible: true,
    )
    a.diff(b)

    check:
      a.label == "B"
      a.onClick == procB
      a.hotkey == keyB
      a.color == blue
      a.invisible == true

suite "Menus - List":
  test "Diff: don't replace for same subtype":
    var a = List[int]()
    let b = List[int]()
    a.diff(b)
    check a != b

  test "Diff: replace for different subtype":
    var a = List[int]().Node
    let b = List[float]().Node
    a.diff(b)
    check a == b
