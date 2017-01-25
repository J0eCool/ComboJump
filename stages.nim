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
  spells/spell_parser,
  areas,
  input,
  enemy_kind,
  entity,
  event,
  game_system,
  jsonparse,
  menu,
  resources,
  spell_creator,
  vec,
  util

type
  Area = object
    info: AreaInfo
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

  Stage* = object
    group*: string
    area*: string
    length*: float
    level*: int
    enemies*: seq[EnemyKind]
  Group* = seq[Stage]

type
  ExitZone* = ref object of Component
    stageEnd*: bool

defineSystem:
  components = [ExitZone, Collider]
  proc updateExitZones*(stageData: var StageData) =
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

proc newTestStageData*(): StageData =
  StageData(
    clickedStage: -1,
    state: inStage,
  )

proc fromJSON*(stageData: var StageData, json: JSON) =
  assert json.kind == jsObject
  stageData.highestStageBeaten.fromJSON(json.obj["highestStageBeaten"])
proc toJSON*(stageData: StageData): JSON =
  result = JSON(kind: jsObject, obj: initTable[string, JSON]())
  result.obj["highestStageBeaten"] = stageData.highestStageBeaten.toJSON()

proc stage(area: AreaInfo, idx: int): Stage =
  let desc = area.stageDesc(idx)
  Stage(
    group: area.name,
    area: $idx,
    length: desc.length,
    level: desc.level,
    enemies: desc.randomEnemyKinds(),
  )

proc name*(stage: Stage): string =
  stage.group & "-" & stage.area

proc `==`*(a, b: Stage): bool =
  a.name == b.name

proc openGroups*(stageData: StageData): seq[Group] =
  result = @[]
  var idx = 0
  for area in areaData:
    var g = newSeq[Stage]()
    for i in 0..<area.numStages:
      g.add area.stage(i + 1)
      if idx > stageData.highestStageBeaten:
        result.add g
        return
      idx += 1
    result.add g

proc pairIndexToLevelIndex(group, stage: int): int =
  for area in areaData[0..<group]:
    result += area.numStages
  result += stage

proc levelIndexToPairIndex(level: int): tuple[group: int, stage: int] =
  var
    group = 0
    level = level
  while level >= areaData[group].numStages:
    level -= areaData[group].numStages
    group += 1
    if group >= areaData.len:
      return (-1, -1)
  return (group, level)

proc click*(stageData: var StageData, group, stage: int) =
  stageData.clickedStage = pairIndexToLevelIndex(group, stage)

proc groupIndexForLevel*(level: int): int =
  level.levelIndexToPairIndex.group

proc currentGroupIndex*(stageData: StageData): int =
  stageData.currentStage.groupIndexForLevel

proc currentStageData*(stageData: StageData): Stage =
  let pair = stageData.currentStage.levelIndexToPairIndex
  areaData[pair.group].stage(pair.stage + 1)
  
proc currentStageName*(stageData: StageData): string =
  stageData.currentStageData.name
