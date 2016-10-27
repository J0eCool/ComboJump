import sdl2

import
  option,
  util,
  vec

type
  Input* = enum
    none,
    left,
    right,
    jump,
    spell1,
    spell2,
    spell3,
    menu,
    restart,
    exit,

  InputState = enum
    inactive,
    pressed,
    held,
    released,

  InputManager* = ref object
    inputs: array[Input, InputState]
    mousePos: Vec
    mouseState: InputState
    mouseWheel: int

proc newInputManager*(): InputManager =
  new result

proc keyToInput(key: Scancode): Input =
  case key
  of SDL_SCANCODE_A: left
  of SDL_SCANCODE_D: right
  of SDL_SCANCODE_K: jump
  of SDL_SCANCODE_J: spell1
  of SDL_SCANCODE_I: spell2
  of SDL_SCANCODE_L: spell3
  of SDL_SCANCODE_R: restart
  of SDL_SCANCODE_ESCAPE: exit
  else: none

proc update*(manager: InputManager) =
  template updateInput(i) =
    if i == pressed:
      i = held
    elif i == released:
      i = inactive
  for i in Input:
    updateInput(manager.inputs[i])
  updateInput(manager.mouseState)
  manager.mouseWheel = 0

  template setForEvent(e, v) =
    let input = keyToInput e.key.keysym.scancode
    if not (v == pressed and manager.inputs[input] == held):
      manager.inputs[input] = v
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      manager.inputs[exit] = pressed
    of KeyDown:
      setForEvent(event, pressed)
    of KeyUp:
      setForEvent(event, released)
    of MouseMotion:
      let pos = vec(event.motion.x, event.motion.y)
      manager.mousePos = pos
    of MouseButtonDown:
      let pos = vec(event.button.x, event.button.y)
      manager.mousePos = pos
      manager.mouseState = pressed
    of MouseButtonUp:
      manager.mouseState = released
    of MouseWheel:
      manager.mouseWheel = event.wheel.y.int
    else: discard

proc isPressed*(manager: InputManager, key: Input): bool =
  manager.inputs[key] == pressed

proc isHeld*(manager: InputManager, key: Input): bool =
  let curState = manager.inputs[key]
  curState == pressed or curState == held

proc isReleased*(manager: InputManager, key: Input): bool =
  manager.inputs[key] == released

proc clickPos*(manager: InputManager): Option[Vec] =
  if manager.mouseState == pressed:
    return makeJust(manager.mousePos)

proc clickHeldPos*(manager: InputManager): Option[Vec] =
  if manager.mouseState == pressed or manager.mouseState == held:
    return makeJust(manager.mousePos)

proc mouseWheel*(manager: InputManager): int =
  manager.mouseWheel
