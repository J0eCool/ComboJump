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
  option,
  rect,
  util,
  vec

suite "Physics - Raycasting":
  proc fromOrigin(dir: Vec): Ray =
    Ray(
      pos: vec(0, 0),
      dir: dir,
      dist: 100,
    )

  proc approxEq(a, b: RaycastHit): bool =
    (a.pos.approxEq(b.pos) and
     a.normal.approxEq(b.normal) and
     a.distance.approxEq(b.distance))

  template checkHit(actual: Option[RaycastHit], expected: RaycastHit) =
    check actual.isJust
    actual.bindAs hit:
      check hit.approxEq(expected)

  let
    right     = fromOrigin(vec( 1,  0))
    left      = fromOrigin(vec(-1,  0))
    up        = fromOrigin(vec( 0, -1))
    down      = fromOrigin(vec( 0,  1))
    downRight = fromOrigin(vec( 3,  4))
  test "Totally non-intersecting doesn't intersect":
    let col = right.intersection(rect(80, 80, 20, 20))
    check col.isNone

  test "Right collision works":
    let col = right.intersection(rect(60, 0, 100, 20))
    checkHit(col, RaycastHit(
      pos: vec(10, 0),
      normal: vec(-1, 0),
      distance: 10,
    ))

  test "Left collision works":
    let col = left.intersection(rect(-20, 0, 20, 20))
    checkHit(col, RaycastHit(
      pos: vec(-10, 0),
      normal: vec(1, 0),
      distance: 10,
    ))

  test "Up collision works":
    let col = up.intersection(rect(0, -20, 20, 20))
    checkHit(col, RaycastHit(
      pos: vec(0, -10),
      normal: vec(0, 1),
      distance: 10,
    ))

  test "Down collision works":
    let col = down.intersection(rect(0, 20, 20, 20))
    checkHit(col, RaycastHit(
      pos: vec(0, 10),
      normal: vec(0, -1),
      distance: 10,
    ))

  test "Distance limits intersection":
    let col = right.intersection(rect(250, 0, 20, 20))
    check col.isNone

  test "Backwards doesn't intersect":
    let col = right.intersection(rect(-50, 0, 20, 20))
    check col.isNone

  test "Dir is normalized":
    let
      ray = fromOrigin(vec(10, 0))
      col = ray.intersection(rect(250, 0, 20, 20))
    check col.isNone

  test "Diagonal collision works (x)":
    let col = downRight.intersection(rect(32, 30, 10, 50))
    checkHit(col, RaycastHit(
      pos: vec(27, 36),
      normal: vec(-1, 0),
      distance: 45,
    ))

  test "Diagonal collision works (y)":
    let col = downRight.intersection(rect(30, 25, 50, 10))
    checkHit(col, RaycastHit(
      pos: vec(15, 20),
      normal: vec(0, -1),
      distance: 25,
    ))

  test "Diagonal collision exact corner is handled":
    let col = downRight.intersection(rect(40, 50, 20, 20))
    checkHit(col, RaycastHit(
      pos: vec(30, 40),
      normal: vec(-1).unit,
      distance: 50,
    ))

  test "Don't intersect with an exact edge":
    let col = right.intersection(rect(30, 10, 20, 20))
    check col.isNone

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

proc vel(entity: Entity): Vec =
  entity.getComponent(Movement).vel

proc onGround(entity: Entity): bool =
  entity.getComponent(Collider).touchingDown

proc isCloseTo(a, b: Vec): bool =
  result = approxEq(a, b, 0.1)
  if not result:
    echo "Playpos = ", a

suite "Physics - Movement":
  let
    singleBlock = testBlock(vec(0), vec(40))
    dt = 1.0

  test "No movement with no velocity":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(50, 0))

  test "Velocity moves":
    let player = testPlayer(vec(50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(100, 0))

  test "Collision stops X movement":
    let player = testPlayer(vec(-50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(-30, 0))

  test "Collision stops Y movement":
    let player = testPlayer(vec(0, -50), vec(0, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(0, -30))

  test "Y collision maintains X velocity":
    let player = testPlayer(vec(0, -50), vec(10, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(10, -30))

  test "Partial collision stops X movement":
    let player = testPlayer(vec(-50, 25), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(-30, 25))

  # test "Can't skip collision with excessive velocity":
  #   let player = testPlayer(vec(0, -50), vec(0, 5000))
  #   discard physics(@[player, singleBlock], dt)
  #   check player.pos.isCloseTo(vec(0, -30))

  test "onGround false when not on ground":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check(not player.onGround)

  test "Falling onto platform sets onGround":
    let player = testPlayer(
      vec(0.0, -50 * gravitySign),
      vec(0.0, 50 * gravitySign))
    discard physics(@[player, singleBlock], dt)
    check player.onGround

  test "Fixes self when starting in ground":
    let player = testPlayer(vec(0, -25), vec(0, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(0, -30))

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
      resultLine.add(if item: tileFilled else: tileEmpty)
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

suite "Physics - TileRoom movement":
  let
    oo = false
    xX = true
    singleBlock = tileGridEntity(vec(-40), vec(40), @[
      @[oo,oo,oo],
      @[oo,xX,oo],
      @[oo,oo,oo],
    ])
    boxRoom = tileGridEntity(vec(-40), vec(20), @[
      @[xX,xX,xX,xX,xX],
      @[xX,oo,oo,oo,xX],
      @[xX,oo,oo,oo,xX],
      @[xX,oo,oo,oo,xX],
      @[xX,xX,xX,xX,xX],
    ])
    dt = 1.0

  test "No movement with no velocity":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player], dt)
    check player.pos.isCloseTo(vec(50, 0))

  test "Velocity moves":
    let player = testPlayer(vec(50, 0), vec(50, 0))
    discard physics(@[player], dt)
    check player.pos.isCloseTo(vec(100, 0))

  test "Collision stops X movement":
    let player = testPlayer(vec(-50, 0), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(-30, 0))

  test "Collision stops Y movement":
    let player = testPlayer(vec(0, -50), vec(0, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(0, -30))

  test "Y collision maintains X velocity":
    let player = testPlayer(vec(0, -50), vec(10, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(10, -30))

  test "Partial collision stops X movement":
    let player = testPlayer(vec(-50, 25), vec(50, 0))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(-30, 25))

  test "Can't get stuck on corners when moving straight":
    let player = testPlayer(vec(-29, -50), vec(0, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(-29, -30))

  test "Can't get stuck on corners when moving diagonally":
    let player = testPlayer(vec(-50, -50), vec(50, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(0, -30))

  test "Can't get stuck on corners when moving diagonally, offset slightly in X":
    let player = testPlayer(vec(-49, -50), vec(50, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(1, -30))

  test "Can't get stuck on corners when moving diagonally, offset slightly in Y":
    let player = testPlayer(vec(-50, -49), vec(50, 50))
    discard physics(@[player, singleBlock], dt)
    check player.pos.isCloseTo(vec(-30, 1))

  # test "Can't skip collision with excessive velocity":
  #   let player = testPlayer(vec(0, -50), vec(0, 5000))
  #   discard physics(@[player, singleBlock], dt)
  #   check player.pos.isCloseTo(vec(0, -30))

  test "onGround false when not on ground":
    let player = testPlayer(vec(50, 0), vec(0))
    discard physics(@[player, singleBlock], dt)
    check(not player.onGround)

  test "Falling onto platform sets onGround":
    let player = testPlayer(
      vec(0.0, -50 * gravitySign),
      vec(0.0, 50 * gravitySign))
    discard physics(@[player, singleBlock], dt)
    check player.onGround

  test "Falling onto platform zeroes Y velocity":
    let player = testPlayer(
      vec(0.0, -50 * gravitySign),
      vec(0.0, 50 * gravitySign))
    discard physics(@[player, singleBlock], dt)
    check player.vel.y == 0.0

  test "Multiple tiles don't stop movement":
    let
      playerRight = testPlayer(vec(-10,  20), vec( 20,   5))
      playerLeft =  testPlayer(vec( 10, -20), vec(-20,  -5))
      playerDown =  testPlayer(vec( 20, -10), vec(  5,  20))
      playerUp =    testPlayer(vec(-20,  10), vec( -5, -20))
      entities = @[
        boxRoom,
        playerRight,
        playerLeft,
        playerDown,
        playerUp,
      ]
    discard physics(entities, dt)
    check:
      playerRight.pos.isCloseTo vec( 10,  20)
      playerLeft.pos.isCloseTo  vec(-10, -20)
      playerDown.pos.isCloseTo  vec( 20,  10)
      playerUp.pos.isCloseTo    vec(-20, -10)
