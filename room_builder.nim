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

type
  TileGrid = seq[seq[bool]]
  Coord = tuple[x, y: int]

proc newGrid(w, h: int): TileGrid =
  result = @[]
  for x in 0..<w:
    var line: seq[bool] = @[]
    for y in 0..<h:
      line.add false
    result.add line

type GridEditor = ref object of Node
  grid: ptr TileGrid
  clickId: int
  clickedSet: HashSet[Coord]
  clickIsSetting: bool
  tileSize: Vec
  hovered: Coord

proc newGridEditor(grid: ptr TileGrid): GridEditor =
  GridEditor(
    pos: vec(120, 120),
    grid: grid,
    clickId: 0,
    clickedSet: initSet[Coord](),
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
  if coord.x < 0 or coord.x >= grid.len:
    return false
  if coord.y < 0 or coord.y >= grid[coord.x].len:
    return false
  return true

proc getTile(editor: GridEditor, coord: Coord): bool =
  if editor.isCoordIsInRange(coord):
    editor.grid[][coord.x][coord.y]
  else:
    false

proc setTile(editor: GridEditor, coord: Coord, val: bool) =
  if editor.isCoordIsInRange(coord):
    editor.grid[][coord.x][coord.y] = val

method drawSelf(editor: GridEditor, renderer: RendererPtr, resources: var ResourceManager) =
  let grid = editor.grid[]
  for x in 0..<grid.len:
    for y in 0..<grid[x].len:
      let
        r = editor.gridRect(x, y)
        color =
          if (x, y) == editor.hovered:
            yellow
          elif grid[x][y]:
            white
          else:
            black
      renderer.fillRect r, color

method updateSelf(editor: GridEditor, input: InputManager) =
  let hovered = editor.posToCoord(input.mousePos)
  editor.hovered = hovered

  if input.isMousePressed:
    editor.clickedSet = initSet[Coord]()
    editor.clickIsSetting = not editor.getTile(hovered)
  if  input.isMouseHeld and
      editor.isCoordIsInRange(hovered) and
      (not editor.clickedSet.contains(hovered)):
    editor.clickedSet.incl(hovered)
    editor.setTile(hovered, editor.clickIsSetting)

type
  RoomBuilder = ref object of Program
    resources: ResourceManager
    menu: Node
    grid: TileGrid

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "Room Builder (prototype)"
  result.grid = newGrid(12, 9)
  result.menu = newGridEditor(addr result.grid)

method update*(program: RoomBuilder, dt: float) =
  menu.update(program.menu, program.input)

  if program.input.isPressed(Input.menu):
    program.shouldExit = true

method draw*(renderer: RendererPtr, program: RoomBuilder) =
  renderer.draw(program.menu, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRoomBuilder(screenSize), screenSize)
