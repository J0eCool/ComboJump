import
  math,
  sdl2

import
  component/[
    collider,
    sprite,
    transform,
  ],
  menu/[
    level_menu,
    quest_menu,
    rune_menu,
    spell_hud_menu,
    stats_menu,
  ],
  nano_mapgen/[
    map_generation,
  ],
  input,
  entity,
  event,
  game_system,
  jsonparse,
  menu,
  prefabs,
  resources,
  stages,
  vec,
  util

defineSystem:
  priority = 100
  proc stageSelect*(player: Entity, input: InputManager, stageData: var StageData, shouldExit: var bool) =
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
      stageData.shouldSave = true
      
    if stageData.clickedStage >= 0:
      stageData.transitionTo = inStage

    while stageData.transitionTo != StageState.none:
      let transition = stageData.transitionTo
      stageData.transitionTo = StageState.none
      case transition
      of inMap:
        result &= event.Event(kind: loadStage, stage: @[
          newEntity("LevelMenu", [LevelMenu().Component]),
          newEntity("StatsMenu", [StatsMenu().Component]),
          newEntity("QuestMenu", [QuestMenu().Component]),
        ])
        stageData.currentStageInProgress = false
      of inStage:
        stageData.currentStage = stageData.clickedStage
        let
          data = stageData.currentStageData
          stage = data.area.entitiesForStage(data.index, player)
        result &= event.Event(kind: loadStage, stage: stage)
        stageData.clickedStage = -1
        stageData.currentStageInProgress = true
      of nextStage:
        let next = stageData.currentStage + 1
        if next.groupIndexForLevel != stageData.currentGroupIndex:
          stageData.transitionTo = inMap
        else:
          stageData.clickedStage = next
          stageData.transitionTo = inStage
      of inSpellBuilder:
        result &= event.Event(kind: loadStage, stage: @[
          newPlayer(vec(300, 200)),
          newHud(),
          newEntity("RuneMenu", [RuneMenu().Component]),
          newEntity("SpellHudMenu", [SpellHudMenu().Component]),
        ])
      else:
        discard
      stageData.state = transition
