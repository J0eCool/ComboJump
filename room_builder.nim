import hashes, sequtils, sets, tables
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
  TileGrid = object
    w, h: int
    data: seq[seq[bool]]
    textureName: string
    subtiles: seq[seq[SubTile]]
  Coord = tuple[x, y: int]
  SubTile = enum
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

proc allTilemapTextures(): seq[string] =
  # TODO: read this from files
  result = @[
    "white-border",
    "white-border-textured",
    "Bricks",
    "DirtTiles",
    "TestBox",
    "TestBox2",
  ]
  assert result.len > 0, "Need to have at least one tilemap texture"

proc updateTilemapTextureIndex(current: string, deltaIndex: int): string =
  let
    textures = allTilemapTextures()
    index = textures.find(current)
  if index < 0:
    return textures[0]
  let newIndex = (index + deltaIndex) mod textures.len
  if newIndex < 0:
    textures[textures.len - 1]
  else:
    textures[newIndex]

proc updateTextureIndex(grid: var TileGrid, deltaIndex: int) =
  grid.textureName = updateTilemapTextureIndex(grid.textureName, deltaIndex)

proc recalculateSubtiles(grid: var TileGrid) =
  grid.subtiles = @[]
  for x in 0..<2*grid.w:
    var line: seq[SubTile] = @[]
    for y in 0..<2*grid.h:
      line.add tileNone
    grid.subtiles.add line

  const numDirs = 4
  type Filter = tuple
    ins: array[numDirs, bool]
    outs: array[numDirs, SubTile]
  const
    deltas: array[numDirs, Coord] = [(0, 0), (1, 0), (0, 1), (1, 1)]
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
          if grid.data[x][y] != filter.ins[k]:
            found = false
            break
        if found:
          for k in 0..<numDirs:
            let
              d = deltas[k]
              x = (2*i + d.x + 1).clamp(0, 2*grid.w - 1)
              y = (2*j + d.y + 1).clamp(0, 2*grid.h - 1)
            grid.subtiles[x][y] = filter.outs[k]

proc newGrid(w, h: int): TileGrid =
  result = TileGrid(
    w: w,
    h: h,
    data: @[],
    textureName: allTilemapTextures()[0],
  )
  for x in 0..<w:
    var line: seq[bool] = @[]
    for y in 0..<h:
      line.add false
    result.data.add line
  result.recalculateSubtiles()

proc clipRect(subtile: SubTile, sprite: SpriteData): Rect =
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

proc loadSprite(grid: TileGrid, resources: var ResourceManager, renderer: RendererPtr): SpriteData =
  let tilemapName = "tilemaps/" & grid.textureName & ".png"
  resources.loadSprite(tilemapName, renderer)

proc toBoolString(grid: seq[seq[bool]]): string =
  result = ""
  for line in grid:
    for item in line:
      result &= (if item: "1" else: "0")

proc fromBoolString(input: string, w, h: int): seq[seq[bool]] =
  result = @[]
  var line = newSeq[bool]();
  for c in input:
    line.add(c == '1')
    if line.len >= h:
      result.add line
      line = @[]

proc toJSON(grid: TileGrid): JSON =
  var obj = initTable[string, JSON]()
  obj["w"] = grid.w.toJSON
  obj["h"] = grid.h.toJSON
  obj["dataStr"] = grid.data.toBoolString.toJSON
  obj["textureName"] = grid.textureName.toJSON
  JSON(kind: jsObject, obj: obj)
proc fromJSON(grid: var TileGrid, json: JSON) =
  assert json.kind == jsObject
  grid.w.fromJSON(json.obj["w"])
  grid.h.fromJSON(json.obj["h"])
  grid.textureName.fromJSON(json.obj["textureName"])
  var dataStr: string
  dataStr.fromJSON(json.obj["dataStr"])
  grid.data = dataStr.fromBoolString(grid.w, grid.h)
  grid.recalculateSubtiles()

type GridEditor = ref object of Node
  grid: ptr TileGrid
  clickId: int
  tileSize: Vec
  hovered: Coord
  drawGridLines: bool
  drawSubtiles: bool

proc newGridEditor(grid: ptr TileGrid): GridEditor =
  GridEditor(
    pos: vec(290, 120),
    grid: grid,
    clickId: 0,
    tileSize: vec(64),
    hovered: (-1, -1),
    drawGridLines: true,
    drawSubtiles: true,
  )

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
  (scaled.x.int, scaled.y.int)

proc isCoordInRange(editor: GridEditor, coord: Coord): bool =
  let grid = editor.grid[]
  ( coord.x >= 0 and coord.x < grid.w and
    coord.y >= 0 and coord.y < grid.h )

proc getTile(editor: GridEditor, coord: Coord): bool =
  if editor.isCoordInRange(coord):
    editor.grid.data[coord.x][coord.y]
  else:
    false

proc setTile(editor: GridEditor, coord: Coord, val: bool) =
  if editor.isCoordInRange(coord):
    editor.grid.data[coord.x][coord.y] = val
    editor.grid[].recalculateSubtiles()

method drawSelf(editor: GridEditor, renderer: RendererPtr, resources: var ResourceManager) =
  const
    tileColor = lightGray
    hoverColor = lightYellow
  let grid = editor.grid[]

  # Draw tiles
  if not editor.drawSubtiles:
    for x in 0..<grid.w:
      for y in 0..<grid.h:
        let isFull = grid.data[x][y]
        if isFull:
          let r = editor.gridRect(x, y)
          renderer.fillRect r, tileColor

  # Draw subtiles
  if editor.drawSubtiles:
    let sprite = grid.loadSprite(resources, renderer)
    for x in 0..<2*grid.w:
      for y in 0..<2*grid.h:
        let tile = grid.subtiles[x][y]
        if tile != tileNone:
          let r = editor.gridRect(x, y, isSubtile=true)
          renderer.draw(sprite, r, tile.clipRect(sprite))

  # Draw hovered tile
  if editor.isCoordInRange(editor.hovered):
    let
      x = editor.hovered.x
      y = editor.hovered.y
    let
      isFull = grid.data[x][y]
      r = editor.gridRect(x, y)
      color =
        if isFull:
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
    if input.isMouseHeld(mouseLeft):
      let delete = input.isHeld(Input.ctrl)
      editor.setTile(hovered, not delete)
    if input.isMouseHeld(mouseRight):
      editor.setTile(hovered, false)
  if input.isPressed(space):
    editor.drawSubtiles = not editor.drawSubtiles
  if input.isPressed(keyG):
    editor.drawGridLines = not editor.drawGridLines

proc tilemapSelectionNode(target: ptr string): Node =
  List[string](
    pos: vec(10, 40),
    spacing: vec(6),
    items: allTilemapTextures,
    listNodes: (proc(texture: string): Node =
      Button(
        size: vec(240, 40),
        onClick: (proc() =
          target[] = texture
        ),
        children: @[
          BorderedTextNode(text: texture).Node,
        ]
      )
    ),
  )

type
  RoomBuilder = ref object of Program
    resources: ResourceManager
    menu: Node
    grid: TileGrid

proc resetGrid(program: RoomBuilder) =
  program.grid = newGrid(14, 10)

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "Room Builder (prototype)"
  result.resources = newResourceManager()
  let loadedJson = readJSONFile(savedTileFile)
  result.resetGrid()
  if loadedJson.kind != jsError:
    result.grid.fromJSON(loadedJson)
  result.menu = Node(
    children: @[
      tilemapSelectionNode(addr result.grid.textureName),
      newGridEditor(addr result.grid),
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
