import
  quick_shoot/[
    entity_menu,
    shop_menu,
  ],
  menu,
  transition,
  vec


type
  TitleScreen = ref object of RootObj
  TitleScreenController = ref object of Controller

proc titleScreenView(menu: TitleScreen, controller: TitleScreenController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: "Quick Shooter",
        fontSize: 72,
      ),
      Button(
        pos: vec(600, 700),
        size: vec(300, 120),
        children: @[BorderedTextNode(text: "START").Node],
        onClick: (proc() =
          let shop = downcast(newShopMenu())
          controller.queueMenu downcast(newTransitionMenu(shop))
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
