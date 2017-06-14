import unittest

import
  component/[
    collider,
    movement,
    room_viewer,
    transform,
  ],
  mapgen/[
    tile,
    tilemap,
    tile_room,
  ],
  system/physics,
  entity,
  util,
  vec

proc testPlayer(pos, vel: Vec): Entity =
  newEntity("Player", [
    Transform(
      pos: pos,
      size: vec(20, 20),
    ),
    Collider(layer: Layer.player),
    Movement(vel: vel),
  ])

proc testBlock(pos, size: Vec): Entity =
  newEntity("Floor", [
    Transform(
      pos: pos,
      size: size,
    ),
    Collider(layer: Layer.floor),
  ])

proc pos(entity: Entity): Vec =
  entity.getComponent(Transform).pos

proc onGround(entity: Entity): bool =
  entity.getComponent(Movement).onGround

suite "Collisions":
  let
    singleBlock = testBlock(vec(0), vec(40))
    dt = 1.0

  test "No movement with no velocity":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(50, 0))

  test "Velocity moves":
    let player = testPlayer(vec(50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(100, 0))

  test "Collision stops X movement":
    let player = testPlayer(vec(-50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(-30, 0))

  test "Collision stops Y movement":
    let player = testPlayer(vec(0, -50), vec(0, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(0, -30))

  test "Y collision maintains X velocity":
    let player = testPlayer(vec(0, -50), vec(10, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(10, -30))

  test "onGround false when not on ground":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check (not player.onGround)

  test "Falling onto platform sets onGround":
    let player = testPlayer(
      vec(0.0, -50 * gravitySign),
      vec(0.0, 50 * gravitySign))
    discard physics(@[player, singleBlock], dt)
    check player.onGround

# Transpose test grids because Rooms are indexed [x][y], but literal
# arrays are written visually [y][x]
proc transpose[T](matrix: seq[seq[T]]): seq[seq[T]] =
  # TODO: actually transpose - for now test data is the same either way
  matrix

suite "Collisions - TileRoom":
  let
    oo: GridTile = {}
    xX: GridTile = {tileFilled}
    emptyTilemap = Tilemap(
      name: "",
      textures: @[""],
      decorationGroups: @[],
    )
    singleBlockGrid = RoomGrid(
      w: 3,
      h: 3,
      data: transpose(@[
        @[oo,oo,oo],
        @[oo,xX,oo],
        @[oo,oo,oo],
      ]),
      tilemap: emptyTilemap,
      seed: 0,
    )
    singleBlock = buildRoomEntity(singleBlockGrid, vec(-40, -40), vec(40))
    dt = 1.0

  test "No movement with no velocity":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(50, 0))

  test "Velocity moves":
    let player = testPlayer(vec(50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(100, 0))

  test "Collision stops X movement":
    let player = testPlayer(vec(-50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(-30, 0))

  test "Collision stops Y movement":
    let player = testPlayer(vec(0, -50), vec(0, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(0, -30))

  test "Y collision maintains X velocity":
    let player = testPlayer(vec(0, -50), vec(10, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.approxEq(vec(10, -30))

  test "onGround false when not on ground":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check (not player.onGround)

  test "Falling onto platform sets onGround":
    let player = testPlayer(
      vec(0.0, -50 * gravitySign),
      vec(0.0, 50 * gravitySign))
    discard physics(@[player, singleBlock], dt)
    check player.onGround
