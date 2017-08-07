import
  rpg_frontier/[
    battle,
    transition,
  ],
  menu,
  vec


type
  LevelSelect = ref object of RootObj
  LevelSelectController = ref object of Controller
    battle: BattleData
    clickedLevel: int

proc newLevelSelectController(battle: BattleData): LevelSelectController =
  LevelSelectController(
    battle: battle,
    clickedLevel: -1,
  )

method pushMenus(controller: LevelSelectController): seq[MenuBase] =
  if controller.clickedLevel != -1:
    controller.clickedLevel = -1
    let battleMenu = downcast(newBattleMenu(controller.battle))
    result = @[downcast(newTransitionMenu(battleMenu))]

proc levelSelectView(menu: LevelSelect, controller: LevelSelectController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "Level Select",
        fontSize: 32,
      ),
      Button(
        pos: vec(200, 300),
        size: vec(200, 60),
        children: @[BorderedTextNode(text: "Level 1").Node],
        onClick: (proc() =
          controller.clickedLevel = 0
        ),
      ),
    ],
  )

proc newLevelSelectMenu*(battle: BattleData): Menu[LevelSelect, LevelSelectController] =
  Menu[LevelSelect, LevelSelectController](
    model: LevelSelect(),
    view: levelSelectView,
    controller: newLevelSelectController(battle),
  )
