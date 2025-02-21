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

const
  savedRoomDir = "assets/rooms/"
  roomFileExt = ".room"
  expectedRoomWidth = 19
  expectedRoomHeight = 15

type
  EditorMenuMode = enum
    roomSelectMode
    tilesetSelectMode
    roomStatsMode
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
    roomW: int
    tileW, tileH: int
    offset: Vec
    lastMousePos: Vec

proc updateRoom(editor: GridEditor) =
  editor.entities = @[buildRoomEntity(editor.grid[], editor.pos, editor.tileSize)]
  # for i in 0..<3:
  #   var grid = editor.grid[]
  #   grid.seed = randomSeed()
  #   let pos = vec(50.0 + 360.0 * i.float, 600.0)
  #   editor.entities.add buildRoomEntity(grid, pos, vec(16))
  editor.grid[].recalculateExits()

proc resetGrid(editor: GridEditor) =
  editor.grid[] = newGrid(expectedRoomWidth, expectedRoomHeight)
  editor.updateRoom()

proc newGridEditor(grid: ptr RoomGrid): GridEditor =
  result = GridEditor(
    pos: vec(310, 60),
    grid: grid,
    clickId: 0,
    tileSize: vec(32),
    hovered: (-1, -1),
    drawGridLines: true,
    drawRoom: false,
    filename: "",
    roomW: 19,
    tileW: 64,
    tileH: 64,
  )
  result.resetGrid()


proc posToCoord(editor: GridEditor, pos: Vec): Coord =
  let
    local = pos - editor.globalPos + editor.tileSize / 2 - editor.offset
    scaled = local / editor.tileSize
  if scaled.x < 0 or scaled.y < 0:
    # Float to int conversion rounds toward zero, so e.g. -0.8 becomes 0, which lets
    # positions that are just off the grid still count as being in grid.
    (-1, -1)
  else:
    (scaled.x.int, scaled.y.int)

proc coordToMapPos(editor: GridEditor, coord: Coord): Vec =
  # Position within the map, so coord(0, 0) -> vec(0, 0), regardless of editor offset
  vec(coord.x * editor.tileW, coord.y * editor.tileH)


proc isCoordInRange(editor: GridEditor, coord: Coord): bool =
  let grid = editor.grid[]
  ( coord.x >= 0 and coord.x < grid.w and
    coord.y >= 0 and coord.y < grid.h )

proc setTile(editor: GridEditor, coord: Coord, state: GridTile) =
  if editor.isCoordInRange(coord):
    editor.grid.data[coord.x][coord.y] = state
    if editor.drawRoom:
      editor.updateRoom()

proc tileColor(tile: GridTile): Color =
  case tile
  of tileEmpty:
    Color()
  of tileFilled:
    lightGray
  of tileRandom:
    red
  of tileRandomGroup:
    green
  of tileExit:
    darkPurple

proc saveCurrentRoom(editor: GridEditor) =
  if editor.filename == "":
    return
  let fullPath = savedRoomDir & editor.filename & roomFileExt
  log info, "Saving room: ", fullPath
  writeJsonFile(fullPath, editor.grid[].toJson, pretty=true)

method drawSelf(editor: GridEditor, renderer: RendererPtr, resources: ResourceManager) =
  const hoverColor = lightYellow
  let grid = editor.grid[]

  # Draw tiles
  if not editor.drawRoom:
    for x in 0..<grid.w:
      for y in 0..<grid.h:
        let tile = grid.data[x][y]
        if tile != tileEmpty:
          let r = editor.tileSize.gridRect(x, y) + editor.globalPos + editor.offset
          renderer.fillRect r, tile.tileColor

  # Draw hovered tile
  if editor.isCoordInRange(editor.hovered):
    let
      x = editor.hovered.x
      y = editor.hovered.y
    let
      tile = grid.data[x][y]
      r = editor.tileSize.gridRect(x, y) + editor.globalPos + editor.offset
      color =
        if tile != tileEmpty:
          average(tile.tileColor, hoverColor)
        else:
          hoverColor
    renderer.fillRect r, color

  # Draw grid lines
  if editor.drawGridLines:
    let
      totalSize = vec(grid.w, grid.h) * editor.tileSize
      offset = editor.pos - editor.tileSize / 2 + editor.offset
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
    if input.isMouseHeld(mouseLeft):
      let toSet =
        if not input.isHeld(Input.ctrl):
          tileFilled
        else:
          tileEmpty
      editor.setTile(hovered, toSet)
    if input.isMouseHeld(mouseRight):
      editor.setTile(hovered, tileEmpty)
    if input.isHeld(n1):
      editor.setTile(hovered, tileRandom)
    if input.isHeld(n2):
      editor.setTile(hovered, tileRandomGroup)
    if input.isHeld(n3):
      editor.setTile(hovered, tileExit)
  if input.isPressed(space):
    editor.drawRoom = not editor.drawRoom
    if editor.drawRoom:
      editor.updateRoom()
  if input.isPressed(keyG):
    editor.drawGridLines = not editor.drawGridLines
  if input.isPressed(keyR):
    editor.grid.seed = randomSeed()
    editor.updateRoom()

  if input.isHeld(Input.ctrl):
    if input.isPressed(Input.keyN):
      editor.resetGrid()
    if input.isPressed(Input.keyS):
      editor.saveCurrentRoom()

  if input.mouseWheel == 1:
    editor.tileSize = editor.tileSize * 1.1
  elif input.mouseWheel == -1:
    editor.tileSize = editor.tileSize / 1.1

  if input.isMouseHeld(mouseMiddle):
     let delta = input.mousePos - editor.lastMousePos
     editor.offset += delta
  editor.lastMousePos = input.mousePos

proc tilemapSelectionNode(editor: GridEditor): Node =
  List[Tilemap](
    spacing: vec(6),
    items: allTilemaps(),
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

proc roomSelectionNode(editor: GridEditor): Node =
  Node(
    children: @[
      InputTextNode(
        pos: vec(120, 20),
        size: vec(240, 40),
        str: addr editor.filename,
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
        items: allRoomPairs(),
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

proc labelNode(label: string, pos: Vec, numPtr: ptr int, onChange: proc() = nil): Node =
  Node(
    children: @[
      BorderedTextNode(
        pos: pos,
        text: label,
      ),
      InputTextNode(
        pos: pos + vec(120, 0),
        size: vec(80, 36),
        num: numPtr,
        onChange: onChange,
      ),
    ],
  )

proc roomStatsNode(editor: GridEditor): Node =
  Node(
    children: @[
      labelNode("Room W", vec(80,  20), addr editor.roomW, (proc() =
        editor.grid[].resizeTo(editor.roomW, editor.grid.h)
      )),
      labelNode("Tile W", vec(80,  60), addr editor.tileW),
      labelNode("Tile H", vec(80, 100), addr editor.tileH),
    ],
  )

type Named[T] = tuple[name: string, item: T]
proc tabSelectNode[T: enum](item: ptr T, options: array[T, Named[Node]]): Node =
  BindNode[T](
    item: (proc(): T = item[]),
    node: (proc(curState: T): Node =
      var states: seq[T] = @[]
      for state in T:
        states.add state
      Node(
        children: @[
          List[T](
            horizontal: true,
            spacing: vec(6),
            items: states,
            listNodes: (proc(state: T): Node =
              let color =
                if state == item[]:
                  rgb(200, 200, 200)
                else:
                  rgb(60, 60, 60)
              Button(
                size: vec(90, 30),
                color: color,
                onClick: (proc() =
                  item[] = state
                ),
                children: @[
                  BorderedTextNode(text: options[state].name).Node,
                ],
              )
            ),
          ),
          Node(
            pos: vec(0, 40),
            children: @[options[curState].item],
          ),
        ],
      )
    ),
  )

proc sidebarNode(editor: GridEditor): Node =
  tabSelectNode[EditorMenuMode](addr editor.mode, [
    roomSelectMode: ("File", roomSelectionNode(editor)),
    tilesetSelectMode: ("Tile", tilemapSelectionNode(editor)),
    roomStatsMode: ("Stats", roomStatsNode(editor)),
  ])

type
  MapData = object
    entities: seq[Entity]
  MainMenuMode = enum
    roomEditMode
    mapEditMode
  RoomBuilderMenu = ref object of Node
    gridEditor: GridEditor
    map: MapData
    mode: MainMenuMode
    mapLen: int

proc refreshMapRooms(roomBuilder: RoomBuilderMenu) =
  randomize()
  roomBuilder.map.entities = @[]
  let
    numRooms = roomBuilder.mapLen
    rooms = allRoomPairs()
  var prevExitHeight = -1
  for x in 0..<numRooms:
    let
      possibleRooms =
        if x == 0:
          rooms.filterIt(it.room.leftExitHeight != -1)
        else:
          rooms.filterIt(it.room.leftExitHeight == prevExitHeight)
      pair = random(possibleRooms)
    var room = pair.room
    let
      tileSize = vec(1100 div (expectedRoomWidth * numRooms))
      xOff = x.float * expectedRoomWidth.float * tileSize.x + 50.0
      pos = vec(xOff, 300.0)
    room.seed = randomSeed()
    roomBuilder.map.entities.add buildRoomEntity(room, pos, tileSize)
    prevExitHeight = room.rightExitHeight

proc mapEditNode(roomBuilder: RoomBuilderMenu): Node =
  Node(
    children: @[
      InputTextNode(
        pos: vec(120, 20),
        size: vec(240, 40),
        num: addr roomBuilder.mapLen,
        onChange: (proc() =
          roomBuilder.refreshMapRooms()
        ),
      ),
      Button(
        pos: vec(120, 70),
        size: vec(240, 40),
        children: @[BorderedTextNode(text: "Reroll").Node],
        onClick: (proc() =
          roomBuilder.refreshMapRooms()
        ),
        hotkey: keyR,
      ),
    ]
  )

proc mainSidebarNode(roomBuilder: RoomBuilderMenu): Node =
  tabSelectNode[MainMenuMode](addr roomBuilder.mode, [
    roomEditMode: ("Room", sidebarNode(roomBuilder.gridEditor)),
    mapEditMode: ("Map", mapEditNode(roomBuilder)),
  ])

method drawSelf(roomBuilder: RoomBuilderMenu, renderer: RendererPtr, resources: ResourceManager) =
  let camera = Camera()
  case roomBuilder.mode
  of roomEditMode:
    if roomBuilder.gridEditor.drawRoom:
      let entities = roomBuilder.gridEditor.entities
      renderer.drawRoomViewers(entities, resources, camera)
      renderer.drawColliders(entities, camera)
    renderer.draw(roomBuilder.gridEditor, resources)
  of mapEditMode:
    renderer.drawRoomViewers(roomBuilder.map.entities, resources, camera)

  let hoverPos = roomBuilder.gridEditor.coordToMapPos(roomBuilder.gridEditor.hovered)
  renderer.drawBorderedText($hoverPos, vec(1100, 850), resources.loadFont("nevis.ttf"))

method updateSelf(roomBuilder: RoomBuilderMenu, manager: var MenuManager, input: InputManager) =
  case roomBuilder.mode
  of roomEditMode:
    roomBuilder.gridEditor.update(manager, input)
  of mapEditMode:
    discard

type
  RoomBuilder = ref object of Program
    resources: ResourceManager
    menu: Node
    grid: RoomGrid
    menuManager: MenuManager

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "TileRoom Builder (prototype)"
  result.resources = newResourceManager()
  result.menuManager = MenuManager()
  let gridEditor = newGridEditor(addr result.grid)
  gridEditor.resetGrid()
  let menu = RoomBuilderMenu(
    gridEditor: gridEditor,
    mapLen: 4,
  )
  menu.refreshMapRooms()
  menu.children = @[mainSidebarNode(menu)]
  result.menu = menu

method update*(program: RoomBuilder, dt: float) =
  menu.update(program.menu, program.menuManager, program.input)

  if program.input.isPressed(Input.keyC):
    debugDrawColliders = not debugDrawColliders

method draw*(renderer: RendererPtr, program: RoomBuilder) =
  renderer.draw(program.menu, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRoomBuilder(screenSize), screenSize)
