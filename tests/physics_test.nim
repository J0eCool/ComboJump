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
  result = @[]
  for y in 0..<matrix[0].len:
    result.add @[]

  for x in 0..<matrix.len:
    for y in 0..<matrix[x].len:
      result[y].add matrix[x][y]

proc toGridTiles(data: seq[seq[bool]]): seq[seq[GridTile]] =
  result = @[]
  for line in data:
    var resultLine = newSeq[GridTile]()
    for item in line:
      resultLine.add(if item: {tileFilled} else: {})
    result.add resultLine

proc tileGridEntity(pos, tileSize: Vec, rawData: seq[seq[bool]]): Entity =
  let
    data = rawData.transpose.toGridTiles
    emptyTilemap = Tilemap(
      name: "",
      textures: @[""],
      decorationGroups: @[],
    )
    grid = RoomGrid(
      w: data.len,
      h: data[0].len,
      data: data,
      tilemap: emptyTilemap,
    )
  buildRoomEntity(grid, pos, tileSize)

suite "Collisions - TileRoom":
  let
    oo = false
    xX = true
    singleBlock = tileGridEntity(vec(-40), vec(40), @[
      @[oo,oo,oo],
      @[oo,xX,oo],
      @[oo,oo,oo],
    ])
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
