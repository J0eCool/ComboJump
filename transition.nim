import
  color,
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
    reverse: bool
  TransitionMenu = Menu[Transition, TransitionController]

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
    color: black,
  )

proc newFadeOnlyIn*(): TransitionMenu

proc transitionUpdate(transition: Transition, controller: TransitionController,
                      dt: float, input: InputManager) {.procvar.} =
  controller.t += dt
  if controller.t >= transitionDuration:
    if controller.reverse or controller.onlyFadeOut:
      controller.shouldPop = true
    else:
      if controller.menu != nil:
        controller.queueMenu controller.menu
        controller.queueMenu downcast(newFadeOnlyIn())
      controller.reverse = true
      controller.t = 0.0

proc newTransitionMenu*(menu: MenuBase): TransitionMenu =
  TransitionMenu(
    model: Transition(),
    view: transitionView,
    update: transitionUpdate,
    controller: TransitionController(
      name: "Transition - NewMenu",
      menu: menu,
    ),
  )

proc newFadeOnlyOut*(): TransitionMenu =
  TransitionMenu(
    model: Transition(),
    view: transitionView,
    update: transitionUpdate,
    controller: TransitionController(
      name: "Transition - FadeOut",
      onlyFadeOut: true,
    ),
  )

proc newFadeOnlyIn*(): TransitionMenu =
  TransitionMenu(
    model: Transition(),
    view: transitionView,
    update: transitionUpdate,
    controller: TransitionController(
      name: "Transition - FadeIn",
      reverse: true,
    ),
  )

method shouldDrawBelow(controller: TransitionController): bool =
  true

proc popWithTransition*(controller: Controller) =
  controller.shouldPop = true
  controller.queueMenu downcast(newFadeOnlyOut())
