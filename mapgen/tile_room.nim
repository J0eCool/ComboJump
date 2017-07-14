import
  random,
  tables,
  strutils

import
  mapgen/[
    tile,
    tilemap,
  ],
  entity,
  jsonparse,
  rect,
  stack,
  util,
  vec

type
  RoomGrid* = object
    w*, h*: int
    data*: seq[seq[GridTile]]
    tilemap*: Tilemap
    seed*: int
  TileRoom* = object
    w*, h*: int
    tilemap*: Tilemap
    tiles*: seq[seq[SubTile]]
  Coord* = tuple[x, y: int]

proc randomSeed*(): int =
  random(int.high)

proc newGrid*(w, h: int): RoomGrid =
  result = RoomGrid(
    w: w,
    h: h,
    data: @[],
    tilemap: allTilemaps()[0],
    seed: randomSeed(),
  )
  for x in 0..<w:
    var line: seq[GridTile] = @[]
    for y in 0..<h:
      line.add(tileEmpty)
    result.data.add line

proc decorate(room: var TileRoom, groups: seq[DecorationGroup]) =
  for group in groups:
    let possibleTextures = group.textures & newSeqOf[string](nil)
    for x in 0..<room.w:
      for y in 0..<room.h:
        let
          kind = room.tiles[x][y].kind
          allowed = group.isKindAllowed(kind)
          maxCount = max(group.maxCount, 1)
          count = random(maxCount div 2, maxCount + 1)
          offsets = randomSubset(group.offsets, count)
        for offset in offsets:
          if not allowed:
            # Maintain rand() call parity
            discard randomBool()
          else:
            let texture = random(possibleTextures)
            if texture != nil:
              room.tiles[x][y].decorations.add Decoration(
                texture: texture,
                offset: offset,
              )

proc buildRoom*(grid: RoomGrid, data: seq[seq[bool]]): TileRoom =
  result = TileRoom(
    w: 2 * grid.w,
    h: 2 * grid.h,
    tilemap: grid.tilemap,
    tiles: @[],
  )
  result.tiles = @[]
  for x in 0..<2*grid.w:
    var line: seq[SubTile] = @[]
    for y in 0..<2*grid.h:
      line.add SubTile(
        kind: tileNone,
        texture: random(grid.tilemap.textures),
        decorations: @[],
      )
    result.tiles.add line

  # Algorithm: Pattern-match the corners where 4 tiles intersect, set the inner subtiles that
  # meet on that corner to the expected output.
  # Consider each tile 4 times, once for each 4 corners it neighbors. The inner subtiles are
  # non-overlapping, and this greatly reduces the number of cases.
  # Also consider the intersections along the border. Extrapolate the tile-settedness for the
  # tiles along the border out.
  const numDirs = 4
  type Filter = tuple
    ins: array[numDirs, bool]
    outs: array[numDirs, SubTileKind]
  const
    deltas: array[numDirs, Coord] =
      [(0, 0), (1, 0), (0, 1), (1, 1)]
    # TODO: instead of iterating through patterns, convert the bools to flags
    # and constant-lookup into an array.
    filters: seq[Filter] = @[
      ([false, false, false, false], [ tileNone,   tileNone,  tileNone,  tileNone]),
      ([false, false, false,  true], [ tileNone,   tileNone,  tileNone,    tileUL]),
      ([false, false,  true, false], [ tileNone,   tileNone,    tileUR,  tileNone]),
      ([false, false,  true,  true], [ tileNone,   tileNone,    tileUC,    tileUC]),
      ([false,  true, false, false], [ tileNone,     tileDL,  tileNone,  tileNone]),
      ([false,  true, false,  true], [ tileNone,     tileCL,  tileNone,    tileCL]),
      ([false,  true,  true, false], [ tileNone,     tileDL,    tileUR,  tileNone]),
      ([false,  true,  true,  true], [ tileNone,     tileCL,    tileUC, tileCorUL]),
      ([ true, false, false, false], [   tileDR,   tileNone,  tileNone,  tileNone]),
      ([ true, false, false,  true], [   tileDR,   tileNone,  tileNone,    tileUL]),
      ([ true, false,  true, false], [   tileCR,   tileNone,    tileCR,  tileNone]),
      ([ true, false,  true,  true], [   tileCR,   tileNone, tileCorUR,    tileUC]),
      ([ true,  true, false, false], [   tileDC,     tileDC,  tileNone,  tileNone]),
      ([ true,  true, false,  true], [   tileDC,  tileCorDL,  tileNone,    tileCL]),
      ([ true,  true,  true, false], [tileCorDR,     tileDC,    tileCR,  tileNone]),
      ([ true,  true,  true,  true], [   tileCC,     tileCC,    tileCC,    tileCC]),
    ]

  for i in -1..grid.w:
    for j in -1..grid.h:
      for filter in filters:
        var found = true
        for k in 0..<numDirs:
          let
            d = deltas[k]
            x = (i + d.x).clamp(0, grid.w - 1)
            y = (j + d.y).clamp(0, grid.h - 1)
          if data[x][y] != filter.ins[k]:
            found = false
            break
        if found:
          for k in 0..<numDirs:
            let
              d = deltas[k]
              x = (2*i + d.x + 1).clamp(0, result.w - 1)
              y = (2*j + d.y + 1).clamp(0, result.h - 1)
            result.tiles[x][y].kind = filter.outs[k]

  result.decorate(grid.tilemap.decorationGroups)

proc walkGroups(grid: seq[seq[GridTile]]): seq[seq[Coord]] =
  var
    visited: seq[seq[bool]] = @[]
  let
    w = grid.len
    h = grid[0].len
  for x in 0..<w:
    var line: seq[bool] = @[]
    for y in 0..<h:
      line.add false
    visited.add line

  proc neighborCoords(pos: Coord): seq[Coord] =
    let
      dxs = [-1, 1, 0, 0]
      dys = [0, 0, -1, 1]
    result = @[]
    for i in 0..<4:
      let
        x = pos.x + dxs[i]
        y = pos.y + dys[i]
      if x < 0 or x >= w or y < 0 or y >= h:
        continue
      result.add((x, y))

  result = @[]
  for x in 0..<w:
    for y in 0..<h:
      if grid[x][y] != tileRandomGroup or visited[x][y]:
        continue

      var
        toVisit = newStack[Coord]()
        toAdd: seq[Coord] = @[]
      toVisit.push((x, y))
      toAdd.add((x, y))
      visited[x][y] = true
      while toVisit.count > 0:
        let
          cur = toVisit.pop()
          neighbors = neighborCoords(cur)
        for pos in neighbors:
          if grid[pos.x][pos.y] != tileRandomGroup or visited[pos.x][pos.y]:
            continue
          visited[pos.x][pos.y] = true
          toVisit.push(pos)
          toAdd.add(pos)
      result.add toAdd


proc selectRandomTiles*(grid: seq[seq[GridTile]]): seq[seq[bool]] =
  result = @[]
  for line in grid:
    var toAdd = newSeq[bool]()
    for tile in line:
      var shouldFill = tile == tileFilled
      if tile == tileRandom and randomBool():
        shouldFill = true
      toAdd.add(shouldFill)
    result.add toAdd
  let groups = grid.walkGroups
  for group in groups:
    if randomBool():
      for pos in group:
        result[pos.x][pos.y] = true

proc toInt(tile: GridTile): int =
  tile.ord

proc fromInt(num: int): GridTile =
  num.GridTile

proc toTileString(grid: seq[seq[GridTile]]): string =
  result = ""
  for line in grid:
    for item in line:
      result &= item.toInt.toHex(1)

proc fromTileString(input: string, w, h: int): seq[seq[GridTile]] =
  result = @[]
  var line = newSeq[GridTile]();
  for c in input:
    line.add(($c).parseHexInt.fromInt)
    if line.len >= h:
      result.add line
      line = @[]

proc toJson*(grid: RoomGrid): Json =
  var obj = initTable[string, Json]()
  obj["w"] = grid.w.toJson
  obj["h"] = grid.h.toJson
  obj["seed"] = grid.seed.toJson
  obj["dataStr"] = grid.data.toTileString.toJson
  obj["tilemap"] = grid.tilemap.name.toJson
  Json(kind: jsObject, obj: obj)
proc fromJson*(grid: var RoomGrid, json: Json) =
  assert json.kind == jsObject
  grid.w.fromJson(json.obj["w"])
  grid.h.fromJson(json.obj["h"])
  grid.seed.fromJson(json.obj["seed"])

  var tilemapName: string
  tilemapName.fromJson(json.obj["tilemap"])
  grid.tilemap = tilemapFromName(tilemapName)

  var dataStr: string
  dataStr.fromJson(json.obj["dataStr"])
  grid.data = dataStr.fromTileString(grid.w, grid.h)

proc gridRect*(tileSize: Vec, x, y: int, isSubtile = false): Rect =
  let
    base = vec(x, y)
    scale = if isSubtile: 0.5 else: 1.0
    size = tileSize * scale
    offset = if isSubtile: -0.5 * size else: vec()
    pos = base * size + offset
  rect(pos, size)
