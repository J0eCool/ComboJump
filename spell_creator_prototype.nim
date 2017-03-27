import sdl2

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

  RuneTile = object
    dirs: array[TileDir, DirKind]

  DirData = tuple[dir: TileDir, kind: DirKind]

  SpellCreatorPrototype = ref object of Game
    menu: Node

proc dirData(tile: RuneTile): seq[DirData] =
  result = @[]
  for dir in TileDir:
    result.add((dir, tile.dirs[dir]))

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

proc textureBase(kind: DirKind): string =
  case kind
  of baseDir:
    "Base"
  of slotDir:
    "SlotRed"
  of arrowDir:
    "ArrowRed"

proc size(dir: TileDir): Vec =
  case dir
  of dirU, dirD:
    vec(36, 28)
  of dirUR, dirDR, dirDL, dirUL:
    vec(28, 28)

proc textureName(data: DirData): string =
  "runes/tiles/" & data.kind.textureBase & data.dir.textureSuffix

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

proc newSpellCreatorPrototype(screenSize: Vec): SpellCreatorPrototype =
  new result
  result.camera.screenSize = screenSize
  result.title = "Spell Creator (prototype)"

method loadEntities(spellCreator: SpellCreatorPrototype) =
  proc tileWithAll(kind: DirKind): RuneTile =
    RuneTile(
      dirs: [
        dirU: kind,
        dirUR: kind,
        dirDR: kind,
        dirD: kind,
        dirDL: kind,
        dirUL: kind,
      ],
    )
  proc randomDir(): DirKind =
    var dirs = newSeq[DirKind]()
    for dir in DirKind:
      dirs.add dir
    dirs.random
  proc randomTile(): RuneTile =
    RuneTile(
      dirs: [
        dirU: randomDir(),
        dirUR: randomDir(),
        dirDR: randomDir(),
        dirD: randomDir(),
        dirDL: randomDir(),
        dirUL: randomDir(),
      ],
    )
  var randTiles = newSeq[Node]()
  for i in 0..5:
    randTiles.add runeTileNode(randomTile(), vec(200 * i - 300, 200))
  spellCreator.menu = Node(
    pos: vec(400, 400),
    children: @[
      runeTileNode(tileWithAll(baseDir), vec(0, 0)),
      runeTileNode(tileWithAll(slotDir), vec(200, 0)),
      runeTileNode(tileWithAll(arrowDir), vec(400, 0)),
    ] & randTiles,
  )

method update*(spellCreator: SpellCreatorPrototype, dt: float) =
  menu.update(spellCreator.menu, spellCreator.input)

method draw*(renderer: RendererPtr, spellCreator: SpellCreatorPrototype) =
  renderer.drawGame(spellCreator)

  renderer.renderSystem(spellCreator.entities, spellCreator.camera)
  renderer.draw(spellCreator.menu, spellCreator.resources)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newSpellCreatorPrototype(screenSize), screenSize)
