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
    group*: string
    area*: string
    length*: float
    enemies*: seq[SpawnInfo]
    runeReward*: Rune
  Group* = seq[Stage]

proc name*(stage: Stage): string =
  stage.group & "-" & stage.area

let
  levels* = @[
    Stage(
      group: "1",
      area: "1",
      length: 500,
      enemies: @[
        (goblin, 4),
      ],
      runeReward: num,
    ),
    Stage(
      group: "1",
      area: "2",
      length: 800,
      enemies: @[
        (goblin, 5),
        (ogre, 1),
      ],
      runeReward: createSpread,
    ),
    Stage(
      group: "1",
      area: "3",
      length: 1200,
      enemies: @[
        (goblin, 8),
        (ogre, 2),
      ],
      runeReward: count,
    ),
    Stage(
      group: "1",
      area: "4",
      length: 1400,
      enemies: @[
        (goblin, 18),
      ],
      runeReward: despawn,
    ),
    Stage(
      group: "1",
      area: "5",
      length: 2400,
      enemies: @[
        (goblin, 22),
        (ogre, 5),
      ],
      runeReward: createBurst,
    ),
    Stage(
      group: "2",
      area: "1",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: turn,
    ),
    Stage(
      group: "2",
      area: "2",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: nearest,
    ),
    Stage(
      group: "2",
      area: "3",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: mult,
    ),
    Stage(
      group: "2",
      area: "4",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: wave,
    ),
    Stage(
      group: "2",
      area: "5",
      length: 800,
      enemies: @[
        (goblin, 10),
      ],
      runeReward: grow,
    ),
    Stage(
      group: "2",
      area: "6",
      length: 800,
      enemies: @[
        (mushroom, 10),
      ],
      runeReward: createSingle,
    ),
  ]

proc currentRuneReward*(stageData: StageData): Rune =
  levels[stageData.currentStage].runeReward

proc groups_calc(): seq[Group] =
  result = @[]
  for stage in levels:
    var groupExists = false
    for stages in result.mitems:
      if stage.group == stages[0].group:
        groupExists = true
        stages.add stage
        break
    if not groupExists:
      result.add @[stage]
let groups* = groups_calc()

proc openGroups*(stageData: StageData): seq[Group] =
  result = @[]
  var idx = 0
  for group in groups:
    var g = newSeq[Stage]()
    for stage in group:
      g.add stage
      if idx > stageData.highestStageBeaten:
        result.add g
        return
      idx += 1
    result.add g

proc pairIndexToLevelIndex(group, stage: int): int =
  for group in groups[0..<group]:
    result += group.len
  result += stage

proc levelIndexToPairIndex(level: int): tuple[group: int, stage: int] =
  var
    group = 0
    level = level
  while level >= groups[group].len:
    level -= groups[group].len
    group += 1
    if group >= groups.len:
      return (-1, -1)
  return (group, level)

proc click*(stageData: var StageData, group, stage: int) =
  stageData.clickedStage = pairIndexToLevelIndex(group, stage)

proc groupIndexForLevel*(level: int): int =
  level.levelIndexToPairIndex.group

proc groupForLevel*(level: int): Group =
  groups[level.groupIndexForLevel]

proc currentGroupIndex*(stageData: StageData): int =
  stageData.currentStage.groupIndexForLevel

proc currentGroup*(stageData: StageData): Group =
  stageData.currentStage.groupForLevel
