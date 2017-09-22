import
  input,
  menu,
  util,
  vec

type
  Transition = ref object of RootObj
  TransitionController = ref object of Controller
    menu: MenuBase
    onlyFadeOut: bool
    t: float
    shouldPush: bool
    reverse: bool

const transitionDuration = 0.3

proc percentDone(controller: TransitionController): float =
  result = clamp(controller.t / transitionDuration, 0.0, 1.0)
  if controller.reverse:
    result = 1.0 - result

proc transitionView(transition: Transition, controller: TransitionController): Node {.procvar.} =
  let size = vec(2400, 900)
  SpriteNode(
    size: size,
    pos: vec(controller.percentDone.lerp(-0.5, 0.5) * size.x, size.y / 2),
  )

proc transitionUpdate(transition: Transition, controller: TransitionController,
                      dt: float, input: InputManager) {.procvar.} =
  controller.t += dt
  if controller.t >= transitionDuration:
    if controller.reverse or controller.onlyFadeOut:
      controller.shouldPop = true
    else:
      controller.shouldPush = true
      controller.reverse = true
      controller.t = 0.0

proc newTransitionMenu*(menu: MenuBase): Menu[Transition, TransitionController] =
  Menu[Transition, TransitionController](
    model: Transition(),
    view: transitionView,
    update: transitionUpdate,
    controller: TransitionController(
      name: "Transition - NewMenu",
      menu: menu,
    ),
  )

proc newFadeOnlyOut*(): Menu[Transition, TransitionController] =
  Menu[Transition, TransitionController](
    model: Transition(),
    view: transitionView,
    update: transitionUpdate,
    controller: TransitionController(
      name: "Transition - FadeOut",
      onlyFadeOut: true,
    ),
  )

proc newFadeOnlyIn*(): Menu[Transition, TransitionController] =
  Menu[Transition, TransitionController](
    model: Transition(),
    view: transitionView,
    update: transitionUpdate,
    controller: TransitionController(
      name: "Transition - FadeIn",
      reverse: true,
    ),
  )

method pushMenus(controller: TransitionController): seq[MenuBase] =
  if controller.shouldPush and controller.menu != nil:
    result = @[
      controller.menu,
      downcast(newFadeOnlyIn()),
    ]
  controller.shouldPush = false

method shouldDrawBelow(controller: TransitionController): bool =
  true
