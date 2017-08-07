import
  rpg_frontier/[
    battle,
    transition,
  ],
  menu,
  vec


type
  TitleScreen = ref object of RootObj
  TitleScreenController = ref object of Controller
    battle: BattleData
    start: bool

method pushMenus(controller: TitleScreenController): seq[MenuBase] =
  if controller.start:
    controller.start = false
    let battleMenu = downcast(newBattleMenu(controller.battle))
    result = @[downcast(newTransitionMenu(battleMenu))]

proc titleScreenView(menu: TitleScreen, controller: TitleScreenController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "RPG Frontier",
        fontSize: 72,
      ),
      Button(
        pos: vec(600, 700),
        size: vec(300, 120),
        children: @[BorderedTextNode(text: "START").Node],
        onClick: (proc() =
          controller.start = true
        ),
      ),
    ],
  )

proc newTitleMenu*(battle: BattleData): Menu[TitleScreen, TitleScreenController] =
  Menu[TitleScreen, TitleScreenController](
    model: TitleScreen(),
    view: titleScreenView,
    controller: TitleScreenController(battle: battle),
  )
