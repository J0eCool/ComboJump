import sdl2, sequtils, tables

import
  component/[
    sprite,
    transform,
  ],
  system/[
    render,
  ],
  camera,
  entity,
  event,
  game,
  game_system,
  menu,
  program,
  util,
  vec

type
  TileDir = enum
    dirU
    dirUR
    dirDR
    dirD
    dirDL
    dirUL

  DirKind = enum
    baseDir
    slotDir
    arrowDir

  DirColor = enum
    noneCol
    redCol
    greenCol

  DirSubData = tuple[kind: DirKind, color: DirColor]
  DirData = tuple[dir: TileDir, kind: DirKind, color: DirColor]

  RuneTile = object
    dirs: array[TileDir, DirSubData]

  Slot = tuple[x: int, y: int]
  RuneGrid = Table[Slot, RuneTile]

  SpellCreatorPrototype = ref object of Game
    menu: Node

proc dirData(tile: RuneTile): seq[DirData] =
  result = @[]
  for dir in TileDir:
    let sub = tile.dirs[dir]
    result.add((dir, sub.kind, sub.color))

proc offset(dir: TileDir): Vec =
  const
    w = 116.0
    h = 76.0
    y = h / 2 - 2
    dx = w / 4 + 7
    dy = h / 4 - 3
  case dir
  of dirU:
    vec(0.0, -y)
  of dirUR:
    vec(dx, -dy)
  of dirDR:
    vec(dx, dy)
  of dirD:
    vec(0.0, y)
  of dirDL:
    vec(-dx, dy)
  of dirUL:
    vec(-dx, -dy)

proc textureSuffix(dir: TileDir): string =
  case dir
  of dirU:
    "U.png"
  of dirUR:
    "UR.png"
  of dirDR:
    "DR.png"
  of dirD:
    "D.png"
  of dirDL:
    "DL.png"
  of dirUL:
    "UL.png"

proc texture(color: DirColor): string =
  case color
  of noneCol:
    "ERROR"
  of redCol:
    "Red"
  of greenCol:
    "Green"

proc textureBase(sub: DirSubData): string =
  case sub.kind
  of baseDir:
    "Base"
  of slotDir:
    "Slot" & sub.color.texture
  of arrowDir:
    "Arrow" & sub.color.texture

proc size(dir: TileDir): Vec =
  case dir
  of dirU, dirD:
    vec(36, 28)
  of dirUR, dirDR, dirDL, dirUL:
    vec(28, 28)

proc subData(data: DirData): DirSubData =
  (data.kind, data.color)

proc textureName(data: DirData): string =
  "runes/tiles/" & data.subData.textureBase & data.dir.textureSuffix

proc runeTileNode(tile: RuneTile, pos: Vec): Node =
  Node(
    pos: pos,
    children: @[
      SpriteNode(
        pos: vec(),
        size: vec(116, 76),
        textureName: "runes/tiles/TileBase.png",
      ),
      SpriteNode(
        pos: vec(),
        size: vec(48, 48),
        textureName: "runes/Burst.png",
      ),
      List[DirData](
        ignoreSpacing: true,
        items: (proc(): seq[DirData] = tile.dirData),
        listNodes: (proc(data: DirData): Node =
          SpriteNode(
            pos: data.dir.offset,
            size: data.dir.size,
            textureName: data.textureName,
          )
        ),
      ),
    ],
  )

proc runeGridNode(grid: RuneGrid): Node =
  List[Slot](
    pos: vec(600, 450),
    ignoreSpacing: true,
    items: (proc(): seq[Slot] = toSeq(grid.keys())),
    listNodes: (proc(slot: Slot): Node =
      runeTileNode(grid[slot], vec(160 * slot.x, 80 * slot.y) / 2),
    ),
  )

proc newSpellCreatorPrototype(screenSize: Vec): SpellCreatorPrototype =
  new result
  result.camera.screenSize = screenSize
  result.title = "Spell Creator (prototype)"

method loadEntities(spellCreator: SpellCreatorPrototype) =
  proc tileWithAll(kind: DirKind): RuneTile =
    RuneTile(
      dirs: [
        dirU: (kind, redCol),
        dirUR: (kind, greenCol),
        dirDR: (kind, redCol),
        dirD: (kind, greenCol),
        dirDL: (kind, redCol),
        dirUL: (kind, greenCol),
      ],
    )

  proc randomDir(): DirKind =
    var dirs = newSeq[DirKind]()
    for dir in DirKind:
      dirs.add dir
    dirs.random
  proc randomCol(): DirColor =
    @[redCol, greenCol].random
  proc randomTile(): RuneTile =
    RuneTile(
      dirs: [
        dirU: (randomDir(), randomCol()),
        dirUR: (randomDir(), randomCol()),
        dirDR: (randomDir(), randomCol()),
        dirD: (randomDir(), randomCol()),
        dirDL: (randomDir(), randomCol()),
        dirUL: (randomDir(), randomCol()),
      ],
    )

  var grid: RuneGrid = initTable[Slot, RuneTile]()
  let
    w = 5
    h = 9
  for i in 0..<w:
    for j in 0..<h:
      let
        dx = if j mod 2 == 0: 0 else: 1
        x = 2 * (i - w div 2) + dx
        y = j - h div 2
      if randomBool(0.5):
        grid[(x, y)] = randomTile()
  spellCreator.menu = runeGridNode(grid)

method update*(spellCreator: SpellCreatorPrototype, dt: float) =
  menu.update(spellCreator.menu, spellCreator.input)

method draw*(renderer: RendererPtr, spellCreator: SpellCreatorPrototype) =
  renderer.drawGame(spellCreator)

  renderer.renderSystem(spellCreator.entities, spellCreator.camera)
  renderer.draw(spellCreator.menu, spellCreator.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newSpellCreatorPrototype(screenSize), screenSize)
