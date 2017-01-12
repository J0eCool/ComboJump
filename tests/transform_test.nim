import unittest

import
  component/transform,
  entity,
  vec

proc entity(transforms: varargs[Transform]): Entity =
  for i in 0..<transforms.len:
    let
      t = transforms[transforms.len - 1 - i]
      children = if result != nil: @[result] else: @[]
    result = newEntity($i, [t.Component], children)

proc lastChild(entity: Entity): Entity =
  result = entity
  for child in entity:
    result = child.lastChild

proc last(entity: Entity): Transform =
  entity.lastChild.getComponent(Transform)

suite "Transform":
  setup:
    let
      A = Transform(
          pos: vec(100, 200),
          size: vec(50, 30),
          scale: vec(2),
        )
      B = Transform(
          pos: vec(100, 200),
          size: vec(50, 30),
          scale: vec(0.5),
        )
      C = Transform(
          pos: vec(100, 200),
          size: vec(50, 30),
        )

  test "Sanity - entity":
    let e = entity(A, B, C)
    check e.getComponent(Transform) == A
    for e1 in e:
      check e1.getComponent(Transform) == B
      for e2 in e1:
        check e2.getComponent(Transform) == C

  test "Sanity - lastChild":
    check entity(A, B, C).lastChild.getComponent(Transform) == C

  test "Sanity - last":
    check entity(A, B, C).last == C

  test "scaleOrDefault":
    check:
      A.scaleOrDefault == vec(2)
      B.scaleOrDefault == vec(0.5)
      C.scaleOrDefault == vec(1)

  test "globalScale":
    check:
      entity(C).last.globalScale == vec(1)
      entity(A, B).last.globalScale == vec(1)
      entity(A, C).last.globalScale == vec(2)
      entity(B, C).last.globalScale == vec(0.5)
      entity(C, B).last.globalScale == vec(0.5)
      entity(A, B, C).last.globalScale == vec(1)
      entity(C, B, A).last.globalScale == vec(1)

  test "globalSize":
    check:
      entity(C).last.globalSize == vec(50, 30)
      entity(A, B).last.globalSize == vec(50, 30)
      entity(A, C).last.globalSize == vec(100, 60)
      entity(B, C).last.globalSize == vec(25, 15)
      entity(C, B).last.globalSize == vec(25, 15)
      entity(A, B, C).last.globalSize == vec(50, 30)
      entity(C, B, A).last.globalSize == vec(50, 30)

  test "globalPos":
    check:
      entity(C).last.globalPos == vec(100, 200)
      entity(A, B).last.globalPos == vec(300, 600)
      entity(A, C).last.globalPos == vec(300, 600)
      entity(B, C).last.globalPos == vec(150, 300)
      entity(C, B).last.globalPos == vec(200, 400)
      entity(A, B, C).last.globalPos == vec(400, 800)
      entity(C, B, A).last.globalPos == vec(250, 500)
