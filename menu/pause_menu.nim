import
  color,
  input,
  menu,
  vec


type
  QuitProc = proc()
  PauseScreen = ref object of RootObj
    onQuit: QuitProc
  PauseScreenController = ref object of Controller

proc pauseScreenView(menu: PauseScreen, controller: PauseScreenController): Node {.procvar.} =
  Node(
    children: @[
      SpriteNode( # Background
        size: vec(1200, 900),
        pos: vec(600, 450),
        color: rgba(0, 0, 0, 128),
      ),
      BorderedTextNode(
        pos: vec(600, 350),
        text: "-= PAUSED =-",
        fontSize: 72,
      ),
      Button(
        pos: vec(600, 600),
        size: vec(300, 60),
        label: "Resume",
        hotkey: Input.enter,
        onClick: (proc() =
          controller.shouldPop = true
        ),
      ),
      Button(
        pos: vec(600, 680),
        size: vec(300, 60),
        label: "Quit to Title",
        hotkey: Input.escape,
        onClick: (proc() =
          controller.shouldPop = true
          menu.onQuit()
        ),
      ),
    ],
  )

proc newPauseMenu*(onQuit: QuitProc): MenuBase =
  downcast(Menu[PauseScreen, PauseScreenController](
    model: PauseScreen(
      onQuit: onQuit,
    ),
    view: pauseScreenView,
    controller: PauseScreenController(),
  ))

method shouldDrawBelow(controller: PauseScreenController): bool =
  true
