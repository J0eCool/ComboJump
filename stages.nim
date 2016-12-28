import
  sdl2,
  sequtils

import
  component/collider,
  component/target_shooter,
  input,
  entity,
  event,
  menu,
  newgun,
  prefabs,
  resources,
  spell_creator,
  system,
  vec,
  util

type
  StageData* = object
    clickedStage: int
    currentStage: int
    highestStageBeaten: int
    currentStageInProgress: bool

proc newStageData*(): StageData =
  StageData(highestStageBeaten: -1)

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
        (goblin, 2),
        (ogre, 1),
      ],
      runeReward: num,
    ),
    Stage(
      name: "1-2",
      length: 800,
      enemies: @[
        (goblin, 7),
        (ogre, 2),
      ],
      runeReward: createSpread,
    ),
    Stage(
      name: "1-3",
      length: 2000,
      enemies: @[
        (goblin, 16),
        (ogre, 4),
      ],
      runeReward: count,
    ),
  ]

proc currentRuneReward(stageData: StageData): Rune =
  stages[stageData.currentStage].runeReward

type
  LevelMenu* = ref object of Component
    menu: Node

proc levelMenuNode(stageData: ptr StageData): Node =
  SpriteNode(
    pos: vec(1020, 680),
    size: vec(300, 400),
    color: color(128, 128, 128, 255),
    children: newSeqOf[Node](
      List[int](
        spacing: vec(10),
        size: vec(300, 400),
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
    newEntity("LevelMenu", [LevelMenu().Component]),
    newEntity("RuneMenu", [RuneMenu().Component]),
    newEntity("SpellHudMenu", [SpellHudMenu().Component]),
  ]
  for spawn in stage.enemies:
    for i in 0..<spawn.count:
      let pos = vec(random(100.0, 700.0), -random(0.0, stage.length))
      result.add newEnemy(spawn.enemy, pos)

defineSystem:
  proc stageSelect*(input: InputManager, stageData: var StageData, spellData: var SpellData) =
    result = @[]

    if input.isPressed(restart):
      stageData.clickedStage = stageData.currentStage

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
      
    if stageData.clickedStage >= 0:
      result &= event.Event(kind: loadStage, stage: stages[stageData.clickedStage].spawnedEntities())
      stageData.currentStage = stageData.clickedStage
      stageData.clickedStage = -1
      stageData.currentStageInProgress = true
