import
  math,
  sdl2

import
  component/[
    collider,
    sprite,
    target_shooter,
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
    room,
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

proc spawnedEntities*(stage: Stage, player: Entity): Entities =
  let
    player = if player != nil: player else: newPlayer(vec())
    playerTransform = player.getComponent(Transform)
    screenSize = vec(1200, 900) # TODO: don't hardcode this
    exitSize = vec(80)
    numRooms = ceil(stage.length / screenSize.y).int + 2
  playerTransform.pos = vec(300, 800)

  result = @[
    player,
    newHud(),
    newEntity("BeginExit", [
      ExitZone(stageEnd: false),
      Collider(layer: playerTrigger),
      Transform(pos: vec(150, 800), size: exitSize),
      Sprite(color: color(0, 0, 0, 255)),
    ]),
    newEntity("EndExit", [
      ExitZone(stageEnd: true),
      Collider(layer: playerTrigger),
      Transform(pos: vec(1050, 100), size: exitSize),
      Sprite(color: color(0, 0, 0, 255)),
    ]),
  ]
  for i in 0..<numRooms:
    let roomPos = vec(0.0, -screenSize.y * i.float)
    result &= roomEntities(screenSize, roomPos)
  for enemy in stage.enemies:
    let pos = vec(random(100.0, 700.0), -random(0.0, stage.length))
    result.add newEnemy(enemy, stage.level, pos)

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
        result &= event.Event(kind: loadStage, stage: stageData.currentStageData.spawnedEntities(player))
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
