import
  input,
  menu,
  transition,
  vec


type
  MenuProc = proc(): MenuBase
  TitleScreen = ref object of RootObj
    titleText: string
    toLoad: MenuProc
  TitleScreenController = ref object of Controller

proc titleScreenView(menu: TitleScreen, controller: TitleScreenController): Node {.procvar.} =
  Node(
    children: @[
      BorderedTextNode(
        pos: vec(600, 150),
        text: menu.titleText,
        fontSize: 72,
      ),
      Button(
        pos: vec(600, 700),
        size: vec(300, 120),
        children: @[BorderedTextNode(text: "START").Node],
        hotkey: Input.enter,
        onClick: (proc() =
          controller.queueMenu downcast(newTransitionMenu(menu.toLoad()))
        ),
      ),
    ],
  )

proc newTitleMenu*(title: string, toLoad: MenuProc): MenuBase =
  downcast(Menu[TitleScreen, TitleScreenController](
    model: TitleScreen(
      titleText: title,
      toLoad: toLoad,
    ),
    view: titleScreenView,
    controller: TitleScreenController(),
  ))
