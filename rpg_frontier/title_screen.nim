import
  rpg_frontier/[
    level_select,
    transition,
  ],
  menu,
  vec


type
  TitleScreen = ref object of RootObj
  TitleScreenController = ref object of Controller
    start: bool

method pushMenus(controller: TitleScreenController): seq[MenuBase] =
  if controller.start:
    controller.start = false
    let levelSelect = downcast(newLevelSelectMenu())
    result = @[downcast(newTransitionMenu(levelSelect))]

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

proc newTitleMenu*(): Menu[TitleScreen, TitleScreenController] =
  Menu[TitleScreen, TitleScreenController](
    model: TitleScreen(),
    view: titleScreenView,
    controller: TitleScreenController(),
  )
