import
  sdl2,
  sequtils,
  tables

import
  component/collider,
  component/sprite,
  component/target_shooter,
  component/transform,
  menu/spell_hud_menu,
  menu/rune_menu,
  input,
  enemy_kind,
  entity,
  event,
  jsonparse,
  menu,
  newgun,
  resources,
  spell_creator,
  system,
  vec,
  util

type
  StageState* = enum
    none
    freshStart
    inMap
    inStage
    nextStage
    inSpellBuilder
  StageData* = object
    clickedStage*: int
    currentStage*: int
    highestStageBeaten*: int
    currentStageInProgress*: bool
    shouldSave*: bool
    state*: StageState
    transitionTo*: StageState
    didCompleteStage*: bool

type
  ExitZone* = ref object of Component
    stageEnd*: bool

defineSystem:
  proc updateExitZones*(stageData: var StageData) =
    entities.forComponents e, [
      ExitZone, exitZone,
      Collider, collider,
    ]:
      if collider.collisions.len > 0:
        stageData.transitionTo = if exitZone.stageEnd: nextStage else: inMap
        if exitZone.stageEnd:
          stageData.didCompleteStage = true

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
  Stage* = object
    name*: string
    length*: float
    enemies*: seq[SpawnInfo]
    runeReward*: Rune

let
  levels* = @[
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
    Stage(
      name: "2-6",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: createSingle,
    ),
  ]

proc currentRuneReward*(stageData: StageData): Rune =
  levels[stageData.currentStage].runeReward
