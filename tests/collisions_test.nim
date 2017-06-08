import unittest

import
  component/[
    collider,
    transform,
  ],
  system/collisions,
  entity,
  util,
  vec

proc testEntity(layer: Layer, pos: Vec, size = vec(20, 20)): Entity =
  newEntity("", [
    Transform(
      pos: pos,
      size: size,
    ),
    Collider(layer: layer),
  ])

proc collisions(entity: Entity): seq[Entity] =
  let collider = entity.getComponent(Collider)
  collider.collisions

proc didCollideWith(a, b: Entity): bool =
  let cols = a.collisions
  cols.len > 0 and b in cols

proc didNotCollide(entity: Entity): bool =
  entity.collisions.len == 0

suite "Collisions":
  test "Not overlapping is not colliding":
    let
      obj = testEntity(player, vec(50, 50))
      floor = testEntity(floor, vec(-50, -50))
    discard checkCollisions(@[obj, floor])
    check obj.didNotCollide()

  test "Overlapping is colliding":
    let
      obj = testEntity(player, vec(50, 50))
      floor = testEntity(floor, vec(40, 40))
    discard checkCollisions(@[obj, floor])
    check obj.didCollideWith(floor)

  test "Buffered adding does not collide immediately":
    let
      obj = testEntity(player, vec(50, 50))
      floor = testEntity(floor, vec(-50, -50))
    let collider = obj.getComponent(Collider)
    collider.bufferedAdd(floor)
    check obj.didNotCollide()

  test "Buffered adding collides a frame later":
    let
      obj = testEntity(player, vec(50, 50))
      floor = testEntity(floor, vec(-50, -50))
    let collider = obj.getComponent(Collider)
    collider.bufferedAdd(floor)
    discard checkCollisions(@[obj, floor])
    check obj.didCollideWith(floor)
