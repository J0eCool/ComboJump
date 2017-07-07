import
  algorithm,
  hashes,
  random,
  ospaths,
  sequtils,
  sets,
  strutils,
  times
from sdl2 import RendererPtr

import
  component/room_viewer,
  mapgen/[
    room_drawing,
    tile,
    tile_room,
    tilemap,
  ],
  system/collisions,
  camera,
  color,
  drawing,
  entity,
  event,
  file_util,
  game_system,
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
    var line: seq[GridTile] = @[]
    for y in 0..<h:
      line.add({})
    result.data.add line

type
  EditorMenuMode = enum
    roomSelectMode
    tilesetSelectMode
  GridEditor = ref object of Node
    grid: ptr RoomGrid
    clickId: int
    tileSize: Vec
    hovered: Coord
    drawGridLines: bool
    drawRoom: bool
    entities: seq[Entity]
    mode: EditorMenuMode
    filename: string

proc updateRoom(editor: GridEditor) =
  editor.entities = @[buildRoomEntity(editor.grid[], editor.pos, editor.tileSize)]
  for i in 0..<3:
    var grid = editor.grid[]
    grid.seed = randomSeed()
    let pos = vec(50.0 + 360.0 * i.float, 600.0)
    editor.entities.add buildRoomEntity(grid, pos, vec(16))

proc newGridEditor(grid: ptr RoomGrid): GridEditor =
  result = GridEditor(
    pos: vec(310, 60),
    grid: grid,
    clickId: 0,
    tileSize: vec(32),
    hovered: (-1, -1),
    drawGridLines: false,
    drawRoom: true,
    filename: "",
  )
  result.updateRoom()

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
          let r = editor.tileSize.gridRect(x, y) + editor.globalPos
          renderer.fillRect r, tileColor
        if tileRandom in tile:
          const numLines = 4
          var r = editor.tileSize.gridRect(x, y) + editor.globalPos
          if tileFilled notin tile:
            renderer.fillRect r, color.gray
          let
            base = r.x
            offset = 2.0
          r.w = 2.0
          for i in 0..<numLines:
            r.x = base + editor.tileSize.x * (i / numLines - 0.5) + offset
            renderer.fillRect r, color.red

  # Draw hovered tile
  if editor.isCoordInRange(editor.hovered):
    let
      x = editor.hovered.x
      y = editor.hovered.y
    let
      tile = grid.data[x][y]
      r = editor.tileSize.gridRect(x, y) + editor.globalPos
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

method updateSelf(editor: GridEditor, manager: var MenuManager, input: InputManager) =
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
        ],
      )
    ),
  )

type RoomPair = tuple[name: string, room: RoomGrid]

proc cmp(a, b: RoomPair): int =
  cmp(a.name, b.name)

const
  savedRoomDir = "assets/rooms/"
  roomFileExt = ".room"
var
  nextWalkRoomTime: float
  cachedRoomPairs = newSeq[RoomPair]()
proc allRoomPairs(): seq[RoomPair] =
  let curTime = epochTime()
  if curTime < nextWalkRoomTime:
    return cachedRoomPairs
  nextWalkRoomTime = curTime + 1.0

  let paths = filesInDirWithExtension(savedRoomDir, roomFileExt)
  result = @[]
  for path in paths:
    var room: RoomGrid
    room.fromJson(readJsonFile(path))
    let name = path.splitFile.name
    result.add((name, room))
  result.sort(cmp)
  cachedRoomPairs = result

proc saveCurrentRoom(editor: GridEditor) =
  let fullPath = savedRoomDir & editor.filename & roomFileExt
  log info, "Saving room: ", fullPath
  writeJsonFile(fullPath, editor.grid[].toJson, pretty=true)

proc roomSelectionNode(editor: GridEditor): Node =
  Node(
    children: @[
      InputTextNode(
        pos: vec(120, 20),
        size: vec(240, 40),
        text: addr editor.filename,
      ),
      Button(
        pos: vec(60, 70),
        size: vec(110, 40),
        children: @[BorderedTextNode(text: "Save").Node],
        onClick: (proc() =
          editor.saveCurrentRoom()
        ),
      ),
      Button(
        pos: vec(190, 70),
        size: vec(120, 40),
        children: @[BorderedTextNode(text: "Load").Node],
        onClick: (proc() =
          let fullPath = savedRoomDir & editor.filename & roomFileExt
          log info, "Loading room: ", fullPath
          let loadedJson = readJsonFile(fullPath)
          if loadedJson.kind != jsError:
            editor.grid[].fromJson(loadedJson)
            editor.updateRoom()
        ),
      ),
      SpriteNode(
        pos: vec(120, 102),
        size: vec(160, 4),
        color: color.darkGray,
      ),
      List[RoomPair](
        pos: vec(0, 110),
        spacing: vec(6),
        items: allRoomPairs,
        listNodes: (proc(pair: RoomPair): Node =
          Button(
            size: vec(240, 40),
            onClick: (proc() =
              editor.filename = pair.name
            ),
            children: @[BorderedTextNode(text: pair.name).Node],
          )
        ),
      ),
    ],
  )

proc sidebarNode(editor: GridEditor): Node =
  BindNode[EditorMenuMode](
    pos: vec(10, 40),
    item: (proc(): EditorMenuMode = editor.mode),
    node: (proc(mode: EditorMenuMode): Node =
      Node(
        children: @[
          List[EditorMenuMode](
            horizontal: true,
            spacing: vec(6),
            items: (proc(): seq[EditorMenuMode] =
              result = @[]
              for mode in EditorMenuMode:
                result.add mode
            ),
            listNodes: (proc(mode: EditorMenuMode): Node =
              let color =
                if mode == editor.mode:
                  rgb(200, 200, 200)
                else:
                  rgb(60, 60, 60)
              Button(
                size: vec(30, 30),
                color: color,
                onClick: (proc() =
                  editor.mode = mode
                ),
                children: @[
                  BorderedTextNode(text: ($mode)[0..0]).Node,
                ],
              )
            ),
          ),
          Node(
            pos: vec(0, 40),
            children: @[
              case mode
              of tilesetSelectMode:
                tilemapSelectionNode(editor)
              of roomSelectMode:
                roomSelectionNode(editor)
            ],
          ),
        ],
      )
    )
  )

type
  RoomBuilder = ref object of Program
    resources: ResourceManager
    editor: GridEditor
    menu: Node
    grid: RoomGrid
    menuManager: MenuManager

proc resetGrid(program: RoomBuilder) =
  program.grid = newGrid(19, 15)

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "TileRoom Builder (prototype)"
  result.resources = newResourceManager()
  result.menuManager = MenuManager()
  result.resetGrid()
  result.editor = newGridEditor(addr result.grid)
  result.menu = Node(
    children: @[
      sidebarNode(result.editor),
      result.editor,
    ]
  )

method update*(program: RoomBuilder, dt: float) =
  menu.update(program.menu, program.menuManager, program.input)

  if program.input.isPressed(Input.menu):
    program.shouldExit = true

  if program.input.isPressed(Input.keyC):
    debugDrawColliders = not debugDrawColliders
  if program.input.isHeld(Input.ctrl):
    if program.input.isPressed(Input.keyN):
      program.resetGrid()
      program.editor.updateRoom()
    if program.input.isPressed(Input.keyS):
      program.editor.saveCurrentRoom()

method draw*(renderer: RendererPtr, program: RoomBuilder) =
  renderer.draw(program.menu, program.resources)
  if program.editor.drawRoom:
    let
      camera = Camera()
      entities = program.editor.entities
    renderer.drawRoomViewers(entities, program.resources, camera)
    renderer.drawColliders(entities, camera)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRoomBuilder(screenSize), screenSize)
