import hashes, sequtils, sets, tables
from sdl2 import RendererPtr

import
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
  Coord = tuple[x, y: int]

proc newGrid(w, h: int): TileGrid =
  result = TileGrid(
    w: w,
    h: h,
    data: @[],
  )
  for x in 0..<w:
    var line: seq[bool] = @[]
    for y in 0..<h:
      line.add false
    result.data.add line

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
  JSON(kind: jsObject, obj: obj)
proc fromJSON(grid: var TileGrid, json: JSON) =
  assert json.kind == jsObject
  grid.w.fromJSON(json.obj["w"])
  grid.h.fromJSON(json.obj["h"])
  var dataStr: string
  dataStr.fromJSON(json.obj["dataStr"])
  grid.data = dataStr.fromBoolString(grid.w, grid.h)

type GridEditor = ref object of Node
  grid: ptr TileGrid
  clickId: int
  tileSize: Vec
  hovered: Coord

proc newGridEditor(grid: ptr TileGrid): GridEditor =
  GridEditor(
    pos: vec(120, 120),
    grid: grid,
    clickId: 0,
    tileSize: vec(60),
    hovered: (-1, -1),
  )

proc gridRect(editor: GridEditor, x, y: int): Rect =
  let pos = vec(x, y) * editor.tileSize + editor.globalPos
  rect(pos, editor.tileSize)

proc posToCoord(editor: GridEditor, pos: Vec): Coord =
  let
    local = pos - editor.globalPos + editor.tileSize / 2
    scaled = local / editor.tileSize
  (scaled.x.int, scaled.y.int)

proc isCoordIsInRange(editor: GridEditor, coord: Coord): bool =
  let grid = editor.grid[]
  ( coord.x >= 0 and coord.x < grid.w and
    coord.y >= 0 and coord.y < grid.h )

proc getTile(editor: GridEditor, coord: Coord): bool =
  if editor.isCoordIsInRange(coord):
    editor.grid.data[coord.x][coord.y]
  else:
    false

proc setTile(editor: GridEditor, coord: Coord, val: bool) =
  if editor.isCoordIsInRange(coord):
    editor.grid.data[coord.x][coord.y] = val

method drawSelf(editor: GridEditor, renderer: RendererPtr, resources: var ResourceManager) =
  const
    tileColor = lightGray
    hoverColor = lightYellow
  let grid = editor.grid[]

  # Draw tiles
  for x in 0..<grid.w:
    for y in 0..<grid.h:
      let
        isFull = grid.data[x][y]
        isHovered = (x, y) == editor.hovered
      if isFull or isHovered:
        let
          r = editor.gridRect(x, y)
          color =
            if isHovered and isFull:
              average(tileColor, hoverColor)
            elif isHovered:
              hoverColor
            else:
              tileColor
        renderer.fillRect r, color

  # Draw grid lines
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

  if input.isMouseHeld and editor.isCoordIsInRange(hovered):
    let value = not input.isHeld(ctrl)
    editor.setTile(hovered, value)

type
  RoomBuilder = ref object of Program
    resources: ResourceManager
    menu: Node
    grid: TileGrid

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "Room Builder (prototype)"
  let loadedJson = readJSONFile(savedTileFile)
  if loadedJson.kind != jsError:
    result.grid.fromJSON(loadedJson)
  else:
    result.grid = newGrid(12, 9)
  result.menu = newGridEditor(addr result.grid)

method update*(program: RoomBuilder, dt: float) =
  menu.update(program.menu, program.input)

  if program.input.isPressed(Input.menu):
    program.shouldExit = true

  if program.input.isHeld(Input.ctrl):
    if program.input.isPressed(Input.keyS):
      writeJSONFile(savedTileFile, program.grid.toJSON, pretty=true)
      log info, "Saved to file ", savedTileFile

method draw*(renderer: RendererPtr, program: RoomBuilder) =
  renderer.draw(program.menu, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRoomBuilder(screenSize), screenSize)
