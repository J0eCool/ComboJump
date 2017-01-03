import
  sdl2,
  sequtils,
  tables

import
  component/collider,
  component/sprite,
  component/target_shooter,
  component/transform,
  input,
  entity,
  event,
  jsonparse,
  menu,
  newgun,
  prefabs,
  resources,
  spell_creator,
  system,
  vec,
  util

type
  StageState = enum
    none
    freshStart
    inMap
    inStage
    inSpellBuilder
  StageData* = object
    clickedStage: int
    currentStage: int
    highestStageBeaten: int
    currentStageInProgress: bool
    shouldSave*: bool
    state: StageState
    transitionTo: StageState
    didCompleteStage: bool

proc newStageData*(): StageData =
  StageData(
    clickedStage: -1, 
    highestStageBeaten: -1, 
    state: freshStart,
  )

proc fromJSON*(stageData: var StageData, json: JSON) =
  assert json.kind == jsObject
  stageData.highestStageBeaten.fromJSON(json.obj["highestStageBeaten"])
proc toJSON*(stageData: StageData): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["highestStageBeaten"] = stageData.highestStageBeaten.toJSON()

type
  SpawnInfo = tuple[enemy: EnemyKind, count: int]
  Stage = object
    name: string
    length: float
    enemies: seq[SpawnInfo]
    runeReward: Rune

let
  stages = @[
    Stage(
      name: "1-1",
      length: 500,
      enemies: @[
        (goblin, 4),
      ],
      runeReward: num,
    ),
    Stage(
      name: "1-2",
      length: 800,
      enemies: @[
        (goblin, 5),
        (ogre, 1),
      ],
      runeReward: createSpread,
    ),
    Stage(
      name: "1-3",
      length: 1200,
      enemies: @[
        (goblin, 8),
        (ogre, 2),
      ],
      runeReward: count,
    ),
    Stage(
      name: "1-4",
      length: 1400,
      enemies: @[
        (goblin, 18),
      ],
      runeReward: despawn,
    ),
    Stage(
      name: "1-5",
      length: 2400,
      enemies: @[
        (goblin, 22),
        (ogre, 5),
      ],
      runeReward: createBurst,
    ),
    Stage(
      name: "2-1",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: turn,
    ),
    Stage(
      name: "2-2",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: nearest,
    ),
    Stage(
      name: "2-3",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: mult,
    ),
    Stage(
      name: "2-4",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: wave,
    ),
    Stage(
      name: "2-5",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: grow,
    ),
  ]

proc currentRuneReward(stageData: StageData): Rune =
  stages[stageData.currentStage].runeReward

type
  LevelMenu* = ref object of Component
    menu: Node

proc maxStageIndex(stageData: StageData): int =
  min(stageData.highestStageBeaten + 1,
      stages.len - 1)

proc maxGroupIndex(stageData: StageData): int =
  min((stageData.highestStageBeaten + 1) div 5,
      (stages.len - 1) div 5)

proc levelMenuNode(stageData: ptr StageData): Node =
  SpriteNode(
    pos: vec(600, 450),
    size: vec(300, 600),
    color: color(128, 128, 128, 255),
    children: @[
      Button(
        pos: vec(40, -265),
        size: vec(200, 50),
        onClick: (proc() =
          stageData.transitionTo = inSpellBuilder
        ),
        children: newSeqOf[Node](
          TextNode(text: "Spell Builder")
        ),
      ),
      TextNode(
        pos: vec(0, -185),
        text: "Stages:",
      ),
      List[int](
        spacing: vec(10),
        pos: vec(0, 26),
        size: vec(300, 400),
        width: 5,
        items: (proc(): seq[int] =
          toSeq(0..stageData[].maxGroupIndex)
        ),
        listNodes: (proc(groupIdx: int): Node =
          var isOpen = false
          Button(
            size: vec(50, 50),
            onClick: (proc() = isOpen = not isOpen),
            children: newSeqOf[Node](
              BindNode[bool](
                item: (proc(): bool = isOpen),
                node: (proc(open: bool): Node =
                  if not open:
                    Node()
                  else:
                    List[int](
                      spacing: vec(10),
                      pos: vec(0, 60),
                      width: 5,
                      items: (proc(): seq[int] =
                        if groupIdx < stageData[].maxGroupIndex:
                          result = toSeq(0..<5)
                        else:
                          result = @[]
                          for i in 0..stageData[].maxStageIndex mod 5:
                            result.add i
                      ),
                      listNodes: (proc(stageIdx: int): Node =
                        let stageIdx = stageIdx + 5 * groupIdx
                        Button(
                          size: vec(50),
                          onClick: (proc() =
                            stageData.clickedStage = stageIdx
                          ),
                          children: @[
                            TextNode(
                              pos: vec(0, -10),
                              text: stages[stageIdx].name,
                            ),
                            SpriteNode(
                              pos: vec(10, 10),
                              size: vec(24, 24),
                              textureName: stages[stageIdx].runeReward.textureName,
                            ),
                          ],
                        )
                      ),
                    )
                ),
              )
            ),
          )
        ),
      ),
    ],
  )

defineDrawSystem:
  priority = -100
  proc drawStageSelectMenu*(resources: var ResourceManager) =
    entities.forComponents entity, [
      LevelMenu, levelMenu,
    ]:
      renderer.draw(levelMenu.menu, resources)

defineSystem:
  proc updateStageSelectMenu*(input: InputManager, stageData: var StageData) =
    entities.forComponents entity, [
      LevelMenu, levelMenu,
    ]:
      if levelMenu.menu == nil:
        levelMenu.menu = levelMenuNode(addr stageData)
      levelMenu.menu.update(input)

type
  ExitZone* = ref object of Component
    stageEnd: bool

proc spawnedEntities(stage: Stage): Entities =
  result = @[
    newPlayer(vec(300, 200)),
    newHud(),
    newEntity("SpellHudMenu", [SpellHudMenu().Component]),
    newEntity("BeginExit", [
      ExitZone(stageEnd: false),
      Collider(layer: playerTrigger),
      Transform(pos: vec(600, 850), size: vec(2000, 1000)),
      Sprite(color: color(0, 0, 0, 255)),
    ]),
    newEntity("EndExit", [
      ExitZone(stageEnd: true),
      Collider(layer: playerTrigger),
      Transform(pos: vec(600.0, -stage.length - 150 - 500), size: vec(2000, 1000)),
      Sprite(color: color(0, 0, 0, 255)),
    ]),
  ]
  for spawn in stage.enemies:
    for i in 0..<spawn.count:
      let pos = vec(random(100.0, 700.0), -random(0.0, stage.length))
      result.add newEnemy(spawn.enemy, pos)

defineSystem:
  proc stageSelect*(input: InputManager, stageData: var StageData, spellData: var SpellData, shouldExit: var bool) =
    result = @[]

    if input.isPressed(restart) and stageData.state == inStage:
      stageData.clickedStage = stageData.currentStage
    if input.isPressed(Input.menu) and stageData.state == inMap:
      shouldExit = true

    if stageData.state == freshStart or (input.isPressed(Input.menu) and stageData.state != inMap):
      stageData.transitionTo = inMap

    if stageData.currentStageInProgress and stageData.didCompleteStage:
      stageData.currentStageInProgress = false
      stageData.didCompleteStage = false
      stageData.highestStageBeaten.max = stageData.currentStage
      spellData.addRuneCapacity(stageData.currentRuneReward())
      stageData.shouldSave = true
      
    if stageData.clickedStage >= 0:
      stageData.transitionTo = inStage

    if stageData.transitionTo != none:
      case stageData.transitionTo
      of inMap:
        result &= event.Event(kind: loadStage, stage: @[
          newEntity("LevelMenu", [LevelMenu().Component]),
        ])
        stageData.currentStageInProgress = false
      of inStage:
        result &= event.Event(kind: loadStage, stage: stages[stageData.clickedStage].spawnedEntities())
        stageData.currentStage = stageData.clickedStage
        stageData.clickedStage = -1
        stageData.currentStageInProgress = true
      of inSpellBuilder:
        result &= event.Event(kind: loadStage, stage: @[
          newPlayer(vec(300, 200)),
          newHud(),
          newEntity("RuneMenu", [RuneMenu().Component]),
          newEntity("SpellHudMenu", [SpellHudMenu().Component]),
        ])
      else:
        discard
      stageData.state = stageData.transitionTo
      stageData.transitionTo = none

defineSystem:
  proc updateExitZones*(stageData: var StageData) =
    entities.forComponents e, [
      ExitZone, exitZone,
      Collider, collider,
    ]:
      if collider.collisions.len > 0:
        stageData.transitionTo = inMap
        if exitZone.stageEnd:
          stageData.didCompleteStage = true
