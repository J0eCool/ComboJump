import
  rpg_frontier/[
    enemy,
    inventory_menu,
    level,
    player_stats,
    skill_select,
  ],
  rpg_frontier/battle/[
    battle_model,
    battle_view,
  ],
  menu,
  transition,
  vec


type
  LevelSelect = ref object of RootObj
    levels: seq[Level]
  LevelSelectController = ref object of Controller
    stats: PlayerStats

proc newLevelSelect(): LevelSelect =
  LevelSelect(
    levels: allLevels,
  )

proc newLevelSelectController(): LevelSelectController =
  LevelSelectController(
    stats: newPlayerStats(),
  )

proc levelSelectView(levels: LevelSelect, controller: LevelSelectController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "Level Select",
        fontSize: 32,
      ),
      Button(
        pos: vec(800, 300),
        size: vec(200, 60),
        label: "Skill Select",
        onClick: (proc() =
          let skillSelectMenu = downcast(newSkillSelectMenu(controller.stats))
          controller.queueMenu downcast(newTransitionMenu(skillSelectMenu))
        ),
      ),
      Button(
        pos: vec(800, 365),
        size: vec(200, 60),
        label: "Inventory",
        onClick: (proc() =
          let inventoryMenu = downcast(newInventoryMenu(controller.stats))
          controller.queueMenu downcast(newTransitionMenu(inventoryMenu))
        ),
      ),
      List[Level](
        pos: vec(200, 300),
        spacing: vec(5),
        items: levels.levels,
        listNodes: (proc(level: Level): Node =
          Button(
            size: vec(200, 60),
            label: level.name,
            onClick: (proc() =
              let
                battle = newBattleData(controller.stats, level)
                battleMenu = downcast(newBattleMenu(battle))
              controller.queueMenu downcast(newTransitionMenu(battleMenu))
            ),
          ),
        ),
      ),
    ],
  )

proc newLevelSelectMenu*(): Menu[LevelSelect, LevelSelectController] =
  Menu[LevelSelect, LevelSelectController](
    model: newLevelSelect(),
    view: levelSelectView,
    controller: newLevelSelectController(),
  )
