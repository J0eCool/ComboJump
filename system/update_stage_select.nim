import
  component/collider,
  component/sprite,
  component/target_shooter,
  component/transform,
  menu/spell_hud_menu,
  menu/rune_menu,
  menu/level_menu,
  input,
  entity,
  event,
  jsonparse,
  menu,
  newgun,
  prefabs,
  resources,
  spell_creator,
  stages,
  system,
  vec,
  util

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

    while stageData.transitionTo != StageState.none:
      let transition = stageData.transitionTo
      stageData.transitionTo = StageState.none
      case transition
      of inMap:
        result &= event.Event(kind: loadStage, stage: @[
          newEntity("LevelMenu", [LevelMenu().Component]),
        ])
        stageData.currentStageInProgress = false
      of inStage:
        result &= event.Event(kind: loadStage, stage: levels[stageData.clickedStage].spawnedEntities())
        stageData.currentStage = stageData.clickedStage
        stageData.clickedStage = -1
        stageData.currentStageInProgress = true
      of nextStage:
        let next = stageData.currentStage + 1
        if next >= levels.len:
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
