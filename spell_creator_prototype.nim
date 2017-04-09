import sdl2, sequtils, tables

import
  component/[
    sprite,
    transform,
  ],
  spells/[
    runes,
    rune_info,
  ],
  system/[
    render,
  ],
  camera,
  color,
  drawing,
  entity,
  event,
  game,
  game_system,
  input,
  menu,
  option,
  program,
  rect,
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

  DirData = tuple[dir: TileDir, kind: DirKind, value: ValueKind]

  RuneTileInfo = object
    dirs: seq[DirData]
    rune: Rune
  RuneTile = object
    info: RuneTileInfo
    rotation: int

  Slot = tuple[x: int, y: int]
  RuneGrid = object
    tiles: Table[Slot, RuneTile]
    w, h: int

  SpellCreatorPrototype = ref object of Game
    menu: Node
    grid: RuneGrid

proc dirData(tile: RuneTile): seq[DirData] =
  result = @[]
  for dir in TileDir:
    let
      rotatedNum = ord(dir) + tile.rotation
      numDirs = ord(high(TileDir)) + 1
      rot = TileDir(rotatedNum mod numDirs)
    result.add((rot, baseDir, number))
    for data in tile.info.dirs:
      if data.dir == dir:
        result[result.len - 1].kind = data.kind
        result[result.len - 1].value = data.value

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

proc texture(kind: ValueKind): string =
  case kind
  of number:
    "Red"
  of projectileInfo:
    "Green"

proc textureName(data: DirData): string =
  let baseName =
    case data.kind
    of baseDir:
      "Base"
    of slotDir:
      "Slot" & data.value.texture
    of arrowDir:
      "Arrow" & data.value.texture
  "runes/tiles/" & baseName & data.dir.textureSuffix

proc size(dir: TileDir): Vec =
  case dir
  of dirU, dirD:
    vec(36, 28)
  of dirUR, dirDR, dirDL, dirUL:
    vec(28, 28)

proc runeTileNode(tile: RuneTile, pos: Vec, onClick: proc()): Node =
  Node(
    pos: pos,
    children: @[
      Button(
        size: vec(56, 60),
        onClick: onClick,
      ),
      SpriteNode(
        size: vec(116, 76),
        textureName: "runes/tiles/TileBase.png",
      ),
      SpriteNode(
        size: vec(48, 48),
        textureName: tile.info.rune.textureName,
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

proc newGrid(w, h: int): RuneGrid =
  RuneGrid(
    w: w,
    h: h,
    tiles: initTable[Slot, RuneTile](),
  )

iterator slots(grid: RuneGrid): Slot =
  for i in 0..<grid.w:
    for j in 0..<grid.h:
      let
        dx = if j mod 2 == 0: 0 else: 1
        x = 2 * (i - grid.w div 2) + dx
        y = j - grid.h div 2
      yield (x, y)

proc slotToPos(grid: RuneGrid, slot: Slot): Vec =
  vec(80 * slot.x + 600, 40 * slot.y + 450)

proc posToSlot(grid: RuneGrid, pos: Vec): Slot =
  # let p = pos - vec(600, 450)
  # var closest = (2 * grid.w, 2 * grid.h)
  # echo "Grid slots:"
  # for slot in grid.slots:
  #   dprint "  ", slot, grid.slotToPos(slot)

  result =
    ( int((pos.x - 600) / 80)
    , int((pos.y - 450) / 40)
    )
  if result.x mod 2 == 1:
    result.x -= 1
  if result.y mod 2 == 0:
    result.x += 1

proc runeGridNode(grid: ptr RuneGrid): Node =
  type Pair = tuple[slot: Slot, tileOpt: Option[RuneTile]]
  proc gridItems(): seq[Pair] =
    result = @[]
    for slot in grid[].slots:
      let tileOpt =
        if grid.tiles.hasKey(slot):
          makeJust(grid.tiles[slot])
        else:
          makeNone[RuneTile]()
      result.add((slot, tileOpt))
  proc gridList(nodes: (proc(pair: Pair): Node)): Node =
    List[Pair](
      ignoreSpacing: true,
      items: gridItems,
      listNodes: nodes,
    )
  Node(
    children: @[
      gridList(proc(pair: Pair): Node =
        SpriteNode(
          pos: slotToPos(grid[], pair.slot),
          size: vec(124, 84),
          textureName: "runes/tiles/HexSpace.png",
        )
      ),
      gridList(proc(pair: Pair): Node =
        let
          slot = pair.slot
          tileOpt = pair.tileOpt
        proc onClick() =
          grid.tiles[slot].rotation += 1
        bindOr(tileOpt, tile,
               Node(),
               runeTileNode(tile, slotToPos(grid[], slot), onClick))
      ),
    ],
  )

proc newSpellCreatorPrototype(screenSize: Vec): SpellCreatorPrototype =
  new result
  result.camera.screenSize = screenSize
  result.title = "Spell Creator (prototype)"

proc tileInfo(rune: Rune): RuneTileInfo =
  result = RuneTileInfo(rune: rune)
  case rune
  of num:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]
  of count:
    result.dirs = @[
      (dirD, arrowDir, number),
      (dirU, slotDir, number),
    ]
  of mult:
    result.dirs = @[
      (dirD, arrowDir, number),
      (dirUL, slotDir, number),
      (dirUR, slotDir, number),
    ]
  of createSingle:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
    ]
  of createSpread:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
      (dirU, slotDir, number),
    ]
  of createBurst:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
      (dirUL, slotDir, number),
    ]

  of createRepeat:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
      (dirDR, slotDir, number),
      (dirUL, slotDir, projectileInfo),
    ]
  of despawn:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
      (dirUR, slotDir, projectileInfo),
    ]
  of wave:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]
  of turn:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
      (dirDL, slotDir, projectileInfo),
      (dirUL, slotDir, number),
    ]
  of grow:
    result.dirs = @[
      (dirD, arrowDir, projectileInfo),
      (dirU, slotDir, projectileInfo),
      (dirUL, slotDir, number),
    ]
  # TODO: non-placeholder below this line
  of moveUp:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]
  of moveSide:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]
  of nearest:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]
  of startPos:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]
  of random:
    result.dirs = @[
      (dirD, arrowDir, number),
    ]

const inputs = [n1, n2, n3, n4, n5, n6, n7, n8, n9, n0, z, x, c, v, b, n, m]

proc placeRune(grid: var RuneGrid, rune: Rune, pos: Vec) =
  let slot = grid.posToSlot(pos)
  grid.tiles[slot] = RuneTile(info: rune.tileInfo)

proc handleInput(grid: var RuneGrid, input: InputManager) =
  for rune in Rune:
    let runeIdx = ord(rune)
    if runeIdx < inputs.len:
      if input.isPressed(inputs[runeIdx]):
        grid.placeRune(rune, input.mousePos)

method loadEntities(spellCreator: SpellCreatorPrototype) =
  proc randomTile(): RuneTile =
    const possibleRunes = @[
      num,
      count,
      mult,
      createSingle,
      createSpread,
      createBurst,
      createRepeat,
      despawn,
      wave,
      turn,
      grow,
      # moveUp,
      # moveSide,
      # nearest,
      # startPos,
      # random,
    ]
    let rune = random(possibleRunes)
    RuneTile(info: rune.tileInfo)
  spellCreator.grid = newGrid(5, 9)
  for slot in spellCreator.grid.slots:
    if randomBool(0.75):
      spellCreator.grid.tiles[slot] = randomTile()
  spellCreator.menu = runeGridNode(addr spellCreator.grid)

method update*(spellCreator: SpellCreatorPrototype, dt: float) =
  handleInput(spellCreator.grid, spellCreator.input)
  menu.update(spellCreator.menu, spellCreator.input)

  if spellCreator.input.isPressed(Input.menu):
    spellCreator.shouldExit = true

method draw*(renderer: RendererPtr, spellCreator: SpellCreatorPrototype) =
  renderer.drawGame(spellCreator)

  renderer.renderSystem(spellCreator.entities, spellCreator.camera)
  renderer.draw(spellCreator.menu, spellCreator.resources)

  let
    grid = spellCreator.grid
    gridPos = grid.slotToPos(grid.posToSlot(spellCreator.input.mousePos))
    size = vec(50, 50)
  renderer.fillRect(rect.rect(gridPos, size), rgb(0, 0, 255))

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newSpellCreatorPrototype(screenSize), screenSize)
