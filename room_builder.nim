import
  algorithm,
  hashes,
  os,
  random,
  sequtils,
  sets,
  strutils,
  tables,
  times
from sdl2 import RendererPtr

import
  component/sprite,
  camera,
  color,
  drawing,
  entity,
  event,
  input,
  jsonparse,
  menu,
  logging,
  option,
  program,
  rect,
  resources,
  stack,
  util,
  vec

const savedTileFile = "saved_room.json"

type
  Decoration = object
    texture: string
    offset: Vec
  DecorationGroup = object
    blacklist: seq[SubTileKind]
    textures: seq[string]
    offsets: seq[Vec]
    maxCount: int
  Tilemap = object
    name: string
    textures: seq[string]
    decorationGroups: seq[DecorationGroup]
  TileState = enum
    tileFilled
    tileRandom
  Tile = set[TileState]
  RoomGrid = object
    w, h: int
    data: seq[seq[Tile]]
    tilemap: Tilemap
    seed: int
  Room = object
    w, h: int
    tilemap: Tilemap
    tiles: seq[seq[SubTile]]
  Coord = tuple[x, y: int]
  SubTile = object
    kind: SubTileKind
    texture: string
    decorations: seq[Decoration]
  SubTileKind = enum
    tileNone
    tileUL
    tileUC
    tileUR
    tileCL
    tileCC
    tileCR
    tileDL
    tileDC
    tileDR
    tileCorUL
    tileCorUR
    tileCorDL
    tileCorDR

autoObjectJSONProcs(DecorationGroup)
autoObjectJSONProcs(Tilemap)

proc cmp(a, b: Tilemap): int =
  cmp(a.name, b.name)

proc walkTilemaps(): seq[string] =
  result = @[]
  for path in os.walkDir("assets/tilemaps"):
    if path.kind == pcFile:
      let split = os.splitFile(path.path)
      if split.ext == ".tilemap":
        result.add path.path

var
  nextWalkTilemapTime: float
  cachedTilemapTextures = newSeq[Tilemap]()
proc allTilemaps(): seq[Tilemap] =
  let curTime = epochTime()
  if curTime < nextWalkTilemapTime:
    return cachedTilemapTextures
  nextWalkTilemapTime = curTime + 1.0

  let paths = walkTilemaps()
  result = @[]
  for path in paths:
    var tilemap: Tilemap
    tilemap.fromJSON(readJSONFile(path))
    result.add tilemap
  assert result.len > 0, "Need to have at least one tilemap texture"
  result.sort(cmp)
  cachedTilemapTextures = result

proc tilemapFromName(name: string): Tilemap =
  for tilemap in allTilemaps():
    if tilemap.name == name:
      return tilemap
  assert false, "Unable to find tilemap: " & name

proc isKindAllowed(group: DecorationGroup, kind: SubTileKind): bool =
  if kind == tileNone:
    return false
  if group.blacklist != nil and kind in group.blacklist:
    return false
  return true

proc randomSubset[T](list: seq[T], count: int): seq[T] =
  let clampedCount = min(list.len, count)
  var copied: seq[T]
  copied.deepCopy(list)
  result = @[]
  for i in 0..<clampedCount:
    let item = random(copied)
    result.add item
    copied.remove(item)

proc decorate(room: var Room, groups: seq[DecorationGroup]) =
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

proc selectRandomTiles(grid: seq[seq[Tile]]): seq[seq[bool]] =
  result = @[]
  for line in grid:
    var toAdd = newSeq[bool]()
    for tile in line:
      var shouldFill = tileFilled in tile
      if tileRandom in tile and randomBool():
        shouldFill = true
      toAdd.add(shouldFill)
    result.add toAdd

proc buildRoom(grid: RoomGrid): Room =
  randomize(grid.seed)
  result = Room(
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

  let data = grid.data.selectRandomTiles()
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

proc randomSeed(): int =
  random(int.high)

proc newGrid(w, h: int): RoomGrid =
  result = RoomGrid(
    w: w,
    h: h,
    data: @[],
    tilemap: allTilemaps()[0],
    seed: randomSeed(),
  )
  for x in 0..<w:
    var line: seq[Tile] = @[]
    for y in 0..<h:
      line.add({})
    result.data.add line

proc clipRect(subtile: SubTileKind, sprite: SpriteData): Rect =
  let
    tileSize = sprite.size.size / vec(5, 3)
    tilePos =
      case subtile
      of tileUL:    vec(0, 0)
      of tileUC:    vec(1, 0)
      of tileUR:    vec(2, 0)
      of tileCL:    vec(0, 1)
      of tileCC:    vec(1, 1)
      of tileCR:    vec(2, 1)
      of tileDL:    vec(0, 2)
      of tileDC:    vec(1, 2)
      of tileDR:    vec(2, 2)
      of tileCorDR: vec(3, 0)
      of tileCorDL: vec(4, 0)
      of tileCorUR: vec(3, 1)
      of tileCorUL: vec(4, 1)
      else:         vec()
  rect(tileSize * tilePos, tileSize)

proc loadSprite(subtile: SubTile, resources: var ResourceManager, renderer: RendererPtr): SpriteData =
  let tilemapName = "tilemaps/" & subtile.texture
  resources.loadSprite(tilemapName, renderer)

proc toInt(tile: Tile): int =
  for state in TileState:
    if state in tile:
      result += 1 shl state.int

proc fromInt(num: int): Tile =
  var x = num
  for state in TileState:
    if (x and 1) != 0:
      result = result + {state}
    x = x shr 1

proc toTileString(grid: seq[seq[Tile]]): string =
  result = ""
  for line in grid:
    for item in line:
      result &= item.toInt.toHex(1)

proc fromTileString(input: string, w, h: int): seq[seq[Tile]] =
  result = @[]
  var line = newSeq[Tile]();
  for c in input:
    line.add(($c).parseHexInt.fromInt)
    if line.len >= h:
      result.add line
      line = @[]

proc toJSON(grid: RoomGrid): JSON =
  var obj = initTable[string, JSON]()
  obj["w"] = grid.w.toJSON
  obj["h"] = grid.h.toJSON
  obj["seed"] = grid.seed.toJSON
  obj["dataStr"] = grid.data.toTileString.toJSON
  obj["tilemap"] = grid.tilemap.name.toJSON
  JSON(kind: jsObject, obj: obj)
proc fromJSON(grid: var RoomGrid, json: JSON) =
  assert json.kind == jsObject
  grid.w.fromJSON(json.obj["w"])
  grid.h.fromJSON(json.obj["h"])
  grid.seed.fromJSON(json.obj["seed"])

  var tilemapName: string
  tilemapName.fromJSON(json.obj["tilemap"])
  grid.tilemap = tilemapFromName(tilemapName)

  var dataStr: string
  dataStr.fromJSON(json.obj["dataStr"])
  grid.data = dataStr.fromTileString(grid.w, grid.h)

type GridEditor = ref object of Node
  grid: ptr RoomGrid
  room: Room
  clickId: int
  tileSize: Vec
  hovered: Coord
  drawGridLines: bool
  drawRoom: bool

proc updateRoom(editor: GridEditor) =
  editor.room = editor.grid[].buildRoom()

proc newGridEditor(grid: ptr RoomGrid): GridEditor =
  result = GridEditor(
    pos: vec(310, 60),
    grid: grid,
    clickId: 0,
    tileSize: vec(32),
    hovered: (-1, -1),
    drawGridLines: false,
    drawRoom: true,
  )
  result.updateRoom()

proc gridRect(editor: GridEditor, x, y: int, isSubtile = false): Rect =
  let
    base = vec(x, y)
    scale = if isSubtile: 0.5 else: 1.0
    size = editor.tileSize * scale
    offset = if isSubtile: -0.5 * size else: vec()
    pos = base * size + offset + editor.globalPos
  rect(pos, size)

proc posToCoord(editor: GridEditor, pos: Vec): Coord =
  let
    local = pos - editor.globalPos + editor.tileSize / 2
    scaled = local / editor.tileSize
  if scaled.x < 0 or scaled.y < 0:
    # Float to int conversion rounds toward zero, so e.g. -0.8 becomes 0, which lets
    # positions that are just off the grid still count as being in grid.
    (-1, -1)
  else:
    (scaled.x.int, scaled.y.int)

proc isCoordInRange(editor: GridEditor, coord: Coord): bool =
  let grid = editor.grid[]
  ( coord.x >= 0 and coord.x < grid.w and
    coord.y >= 0 and coord.y < grid.h )

proc setTile(editor: GridEditor, coord: Coord, state: TileState, val: bool) =
  if editor.isCoordInRange(coord):
    if val:
      editor.grid.data[coord.x][coord.y].incl(state)
    else:
      editor.grid.data[coord.x][coord.y].excl(state)

method drawSelf(editor: GridEditor, renderer: RendererPtr, resources: var ResourceManager) =
  const
    tileColor = lightGray
    hoverColor = lightYellow
  let grid = editor.grid[]

  # Draw tiles
  if not editor.drawRoom:
    for x in 0..<grid.w:
      for y in 0..<grid.h:
        let tile = grid.data[x][y]
        if tileFilled in tile:
          let r = editor.gridRect(x, y)
          renderer.fillRect r, tileColor
        if tileRandom in tile:
          const numLines = 4
          var r = editor.gridRect(x, y)
          if tileFilled notin tile:
            renderer.fillRect r, color.gray
          let
            base = r.x
            offset = 2.0
          r.w = 2.0
          for i in 0..<numLines:
            r.x = base + editor.tileSize.x * (i / numLines - 0.5) + offset
            renderer.fillRect r, color.red

  # Draw subtiles
  if editor.drawRoom:
    let room = editor.room
    for x in 0..<room.w:
      for y in 0..<room.h:
        let tile = room.tiles[x][y]
        if tile.kind != tileNone:
          let
            sprite = tile.loadSprite(resources, renderer)
            r = editor.gridRect(x, y, isSubtile=true)
            scale = editor.tileSize.x * 5 / sprite.size.size.x / 2
          renderer.draw(sprite, r, tile.kind.clipRect(sprite))
          for deco in tile.decorations:
            let
              decoSprite = resources.loadSprite("tilemaps/" & deco.texture, renderer)
              decoRect = rect(r.pos + scale * deco.offset,
                              scale * decoSprite.size.size)
            renderer.draw(decoSprite, decoRect)

  # Draw hovered tile
  if editor.isCoordInRange(editor.hovered):
    let
      x = editor.hovered.x
      y = editor.hovered.y
    let
      tile = grid.data[x][y]
      r = editor.gridRect(x, y)
      color =
        if tileFilled in tile:
          average(tileColor, hoverColor)
        else:
          hoverColor
    renderer.fillRect r, color

  # Draw grid lines
  if editor.drawGridLines:
    let
      totalSize = vec(grid.w, grid.h) * editor.tileSize
      offset = editor.pos - editor.tileSize / 2
      lineWidth = 2.0
      lineColor = darkGray
    for x in 0..grid.w:
      let
        pos = vec(x.float * editor.tileSize.x, totalSize.y / 2) + offset
        r = rect(pos, vec(lineWidth, totalSize.y))
      renderer.fillRect r, lineColor
    for y in 0..grid.h:
      let
        pos = vec(totalSize.x / 2, y.float * editor.tileSize.y) + offset
        r = rect(pos, vec(totalSize.x, lineWidth))
      renderer.fillRect r, lineColor

method updateSelf(editor: GridEditor, input: InputManager) =
  let hovered = editor.posToCoord(input.mousePos)
  editor.hovered = hovered

  if editor.isCoordInRange(hovered):
    let delete = input.isHeld(Input.ctrl)
    if input.isMouseHeld(mouseLeft):
      editor.setTile(hovered, tileFilled, not delete)
      editor.updateRoom()
    if input.isMouseHeld(mouseRight):
      editor.setTile(hovered, tileFilled, false)
      editor.updateRoom()
    if input.isHeld(n1):
      editor.setTile(hovered, tileRandom, not delete)
      editor.updateRoom()
  if input.isPressed(space):
    editor.drawRoom = not editor.drawRoom
    if editor.drawRoom:
      editor.updateRoom()
  if input.isPressed(keyG):
    editor.drawGridLines = not editor.drawGridLines
  if input.isPressed(keyR):
    editor.grid.seed = randomSeed()
    editor.updateRoom()

proc tilemapSelectionNode(editor: GridEditor): Node =
  List[Tilemap](
    pos: vec(10, 40),
    spacing: vec(6),
    items: allTilemaps,
    listNodes: (proc(tilemap: Tilemap): Node =
      Button(
        size: vec(240, 40),
        onClick: (proc() =
          editor.grid.tilemap = tilemap
          editor.updateRoom()
        ),
        children: @[
          BorderedTextNode(text: tilemap.name).Node,
        ]
      )
    ),
  )

type
  RoomBuilder = ref object of Program
    resources: ResourceManager
    menu: Node
    grid: RoomGrid

proc resetGrid(program: RoomBuilder) =
  program.grid = newGrid(19, 16)

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "Room Builder (prototype)"
  result.resources = newResourceManager()
  let loadedJson = readJSONFile(savedTileFile)
  result.resetGrid()
  if loadedJson.kind != jsError:
    result.grid.fromJSON(loadedJson)
  let editor = newGridEditor(addr result.grid)
  result.menu = Node(
    children: @[
      tilemapSelectionNode(editor),
      editor,
    ]
  )

method update*(program: RoomBuilder, dt: float) =
  menu.update(program.menu, program.input)

  if program.input.isPressed(Input.menu):
    program.shouldExit = true

  if program.input.isHeld(Input.ctrl):
    if program.input.isPressed(Input.keyN):
      program.resetGrid()
    if program.input.isPressed(Input.keyS):
      writeJSONFile(savedTileFile, program.grid.toJSON, pretty=true)
      log info, "Saved to file ", savedTileFile

method draw*(renderer: RendererPtr, program: RoomBuilder) =
  renderer.draw(program.menu, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRoomBuilder(screenSize), screenSize)
