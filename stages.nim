import
  sdl2,
  sequtils,
  tables

import
  component/collider,
  component/target_shooter,
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
    freshStart
    inMap
    inStage
  StageData* = object
    clickedStage: int
    currentStage: int
    highestStageBeaten: int
    currentStageInProgress: bool
    shouldSave*: bool
    state: StageState

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

proc levelMenuNode(stageData: ptr StageData): Node =
  SpriteNode(
    pos: vec(1020, 780),
    size: vec(300, 200),
    color: color(128, 128, 128, 255),
    children: newSeqOf[Node](
      List[int](
        spacing: vec(10),
        size: vec(300, 200),
        width: 5,
        items: (proc(): seq[int] =
          toSeq(0..min(stageData.highestStageBeaten + 1,
                       stages.len - 1))
        ),
        listNodes: (proc(stageIdx: int): Node =
          Button(
            size: vec(50, 50),
            onClick: (proc() =
              stageData.clickedStage = stageIdx
            ),
            children: @[
              BindNode[int](
                item: (proc(): int = stageData.currentStage),
                node: (proc(curr: int): Node =
                  TextNode(
                    pos: vec(0, -10),
                    text: stages[stageIdx].name,
                    color:
                      if stageIdx == curr:
                        color(32, 200, 32, 255)
                      else:
                        color(0, 0, 0, 255),
                  )
                ),
              ),
              SpriteNode(
                pos: vec(10, 10),
                size: vec(24, 24),
                textureName: stages[stageIdx].runeReward.textureName,
              ),
            ],
          )
        ),
      ),
    ),
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

proc spawnedEntities(stage: Stage): Entities =
  result = @[
    newPlayer(vec(300, 200)),
    newEntity("RuneMenu", [RuneMenu().Component]),
    newEntity("SpellHudMenu", [SpellHudMenu().Component]),
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

    if stageData.state == freshStart or (input.isPressed(Input.menu) and stageData.state == inStage):
      stageData.state = inMap
      stageData.currentStageInProgress = false
      result &= event.Event(kind: loadStage, stage: @[
        newEntity("LevelMenu", [LevelMenu().Component]),
      ])

    if stageData.currentStageInProgress:
      var didFindEnemy = false
      entities.forComponents e, [
        Collider, collider,
      ]:
        if collider.layer == enemy:
          didFindEnemy = true
          break
      if not didFindEnemy:
        stageData.highestStageBeaten.max = stageData.currentStage
        stageData.currentStageInProgress = false
        spellData.addRuneCapacity(stageData.currentRuneReward())
        stageData.shouldSave = true
      
    if stageData.clickedStage >= 0:
      stageData.state = inStage
      result &= event.Event(kind: loadStage, stage: stages[stageData.clickedStage].spawnedEntities())
      stageData.currentStage = stageData.clickedStage
      stageData.clickedStage = -1
      stageData.currentStageInProgress = true
