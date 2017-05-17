import sdl2, sequtils, tables

import
  camera,
  color,
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
  RoomBuilder = ref object of Program
    resources: ResourceManager
    menu: Node
    grid: TileGrid

proc newGrid(w, h: int): TileGrid =
  result = @[]
  for y in 0..<h:
    var line: seq[bool] = @[]
    for x in 0..<w:
      line.add false
    result.add line

proc gridNode(grid: ptr TileGrid): Node =
  let
    tileSize = vec(60)
  List[seq[bool]](
    pos: vec(120),
    items: (proc(): seq[seq[bool]] = grid[]),
    spacing: tileSize,
    listNodesIdx: (proc(line: seq[bool], y: int): Node =
      List[bool](
        items: (proc(): seq[bool] = line),
        horizontal: true,
        listNodesIdx: (proc(isSet: bool, x: int): Node =
          Button(
            size: tileSize,
            color: if isSet: white else: black,
            onClick: (proc() =
              (grid[])[y][x] = not isSet
            ),
          )
        ),
      )
    ),
  )

proc newRoomBuilder(screenSize: Vec): RoomBuilder =
  new result
  result.title = "Room Builder (prototype)"
  result.grid = newGrid(12, 9)
  result.menu = gridNode(addr result.grid)

method update*(program: RoomBuilder, dt: float) =
  menu.update(program.menu, program.input)

  if program.input.isPressed(Input.menu):
    program.shouldExit = true

method draw*(renderer: RendererPtr, program: RoomBuilder) =
  renderer.draw(program.menu, program.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newRoomBuilder(screenSize), screenSize)
