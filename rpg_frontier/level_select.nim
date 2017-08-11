import
  rpg_frontier/[
    battle,
    enemy,
    level,
    player_stats,
    transition,
  ],
  menu,
  option,
  vec


type
  LevelSelect = ref object of RootObj
    levels: seq[Level]
  LevelSelectController = ref object of Controller
    stats: PlayerStats
    clickedLevel: Option[Level]

proc newLevelSelect(): LevelSelect =
  LevelSelect(
    levels: allLevels,
  )

proc newLevelSelectController(): LevelSelectController =
  LevelSelectController(
    stats: newPlayerStats(),
  )

method pushMenus(controller: LevelSelectController): seq[MenuBase] =
  controller.clickedLevel.bindAs level:
    controller.clickedLevel = makeNone[Level]()
    let
      battle = newBattleData(controller.stats, level)
      battleMenu = downcast(newBattleMenu(battle))
    result = @[downcast(newTransitionMenu(battleMenu))]

proc levelSelectView(levels: LevelSelect, controller: LevelSelectController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "Level Select",
        fontSize: 32,
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
              controller.clickedLevel = makeJust(level)
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
