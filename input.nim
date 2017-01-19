import sdl2

import
  option,
  util,
  vec

type
  Input* = enum
    none
    left
    right
    up
    down
    jump
    spell1
    spell2
    spell3
    menu
    restart
    backspace
    delete
    quit

    n1
    n2
    n3
    n4
    n5
    n6
    n7
    n8
    n9
    n0
    z
    x
    c
    v
    b
    n
    m
    runeLeft
    runeRight
    runeUp
    runeDown


  InputState* = enum
    inactive,
    pressed,
    held,
    released,

  Axis* = enum
    horizontal
    vertical

  InputManager* = object
    inputs: array[Input, InputState]
    axes: array[Axis, int]
    mousePos: Vec
    mouseState: InputState
    mouseWheel: int

  InputPair* = tuple[input: Input, state: InputState]

proc newInputManager*(): InputManager =
  InputManager()

proc inputFromPairs*(statePairs: seq[InputPair]): InputManager =
  var inputs: array[Input, InputState]
  for pair in statePairs:
    inputs[pair.input] = pair.state
  InputManager(
    inputs: inputs,
  )

proc keyToInput(key: Scancode): Input =
  case key
  of SDL_SCANCODE_A: left
  of SDL_SCANCODE_D: right
  of SDL_SCANCODE_W: up
  of SDL_SCANCODE_S: down
  of SDL_SCANCODE_K: jump
  of SDL_SCANCODE_J: spell1
  of SDL_SCANCODE_I: spell2
  of SDL_SCANCODE_L: spell3
  of SDL_SCANCODE_R: restart
  of SDL_SCANCODE_ESCAPE: menu
  of SDL_SCANCODE_BACKSPACE: backspace
  of SDL_SCANCODE_DELETE: delete

  of SDL_SCANCODE_1: n1
  of SDL_SCANCODE_2: n2
  of SDL_SCANCODE_3: n3
  of SDL_SCANCODE_4: n4
  of SDL_SCANCODE_5: n5
  of SDL_SCANCODE_6: n6
  of SDL_SCANCODE_7: n7
  of SDL_SCANCODE_8: n8
  of SDL_SCANCODE_9: n9
  of SDL_SCANCODE_0: n0
  of SDL_SCANCODE_Z: z
  of SDL_SCANCODE_X: x
  of SDL_SCANCODE_C: c
  of SDL_SCANCODE_V: v
  of SDL_SCANCODE_B: b
  of SDL_SCANCODE_N: n
  of SDL_SCANCODE_M: m
  of SDL_SCANCODE_LEFT: runeLeft
  of SDL_SCANCODE_RIGHT: runeRight
  of SDL_SCANCODE_UP: runeUp
  of SDL_SCANCODE_DOWN: runeDown
  else: none

proc isHeld*(manager: InputManager, key: Input): bool
proc update*(manager: var InputManager) =
  template updateInput(i) =
    if i == pressed:
      i = held
    elif i == released:
      i = inactive
  for i in Input:
    updateInput(manager.inputs[i])
  updateInput(manager.mouseState)
  manager.mouseWheel = 0

  template updateAxis(a, neg, pos) =
    var val = 0
    if manager.isHeld(neg):
      val -= 1
    if manager.isHeld(pos):
      val += 1
    manager.axes[a] = val
  updateAxis(horizontal, left, right)
  updateAxis(vertical, up, down)

  template setForEvent(e, v) =
    let input = keyToInput e.key.keysym.scancode
    if not (v == pressed and manager.inputs[input] == held):
      manager.inputs[input] = v
  var event = defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent:
      manager.inputs[quit] = pressed
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

proc mousePos*(manager: InputManager): Vec =
  manager.mousePos

proc clickPressedPos*(manager: InputManager): Option[Vec] =
  if manager.mouseState == pressed:
    return makeJust(manager.mousePos)

proc clickHeldPos*(manager: InputManager): Option[Vec] =
  if manager.mouseState == pressed or manager.mouseState == held:
    return makeJust(manager.mousePos)

proc clickReleasedPos*(manager: InputManager): Option[Vec] =
  if manager.mouseState == released:
    return makeJust(manager.mousePos)

proc mouseWheel*(manager: InputManager): int =
  manager.mouseWheel

proc getAxis*(manager: InputManager, axis: Axis): int =
  manager.axes[axis]
