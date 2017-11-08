import sdl2, strutils

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
    space
    backspace
    delete
    quit
    escape
    enter

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

    ctrl
    shift
    alt

    arrowLeft
    arrowRight
    arrowUp
    arrowDown

    f5

    n0
    n1
    n2
    n3
    n4
    n5
    n6
    n7
    n8
    n9

    keyA
    keyB
    keyC
    keyD
    keyE
    keyF
    keyG
    keyH
    keyI
    keyJ
    keyK
    keyL
    keyM
    keyN
    keyO
    keyP
    keyQ
    keyR
    keyS
    keyT
    keyU
    keyV
    keyW
    keyX
    keyY
    keyZ


  InputState* = enum
    inactive
    pressed
    held
    released

  Axis* = enum
    horizontal
    vertical

  MouseButton* = enum
    mouseLeft
    mouseRight
    mouseMiddle

  InputEvent* = object
    kind*: Input
    state*: InputState
    pos*: Vec

  InputManager* = object
    inputs: array[Input, InputState]
    axes: array[Axis, int]
    mousePos: Vec
    mouseState: array[MouseButton, InputState]
    mouseWheel: int
    bufferedEvents: seq[InputEvent]

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

proc keyToInputs(key: Scancode): seq[Input] =
  case key
  of SDL_SCANCODE_ESCAPE:    @[escape, menu]
  of SDL_SCANCODE_RETURN:    @[enter]
  of SDL_SCANCODE_SPACE:     @[space]
  of SDL_SCANCODE_BACKSPACE: @[backspace]
  of SDL_SCANCODE_DELETE:    @[delete]

  of SDL_SCANCODE_LCTRL:     @[ctrl]
  of SDL_SCANCODE_LSHIFT:    @[shift]
  of SDL_SCANCODE_LALT:      @[alt]

  of SDL_SCANCODE_LEFT:      @[arrowLeft, runeLeft]
  of SDL_SCANCODE_RIGHT:     @[arrowRight, runeRight]
  of SDL_SCANCODE_UP:        @[arrowUp, runeUp]
  of SDL_SCANCODE_DOWN:      @[arrowDown, runeDown]

  of SDL_SCANCODE_F5:        @[f5]

  of SDL_SCANCODE_1:         @[n1]
  of SDL_SCANCODE_2:         @[n2]
  of SDL_SCANCODE_3:         @[n3]
  of SDL_SCANCODE_4:         @[n4]
  of SDL_SCANCODE_5:         @[n5]
  of SDL_SCANCODE_6:         @[n6]
  of SDL_SCANCODE_7:         @[n7]
  of SDL_SCANCODE_8:         @[n8]
  of SDL_SCANCODE_9:         @[n9]
  of SDL_SCANCODE_0:         @[n0]

  of SDL_SCANCODE_A:         @[keyA, left]
  of SDL_SCANCODE_B:         @[keyB, b]
  of SDL_SCANCODE_C:         @[keyC, c]
  of SDL_SCANCODE_D:         @[keyD, right]
  of SDL_SCANCODE_E:         @[keyE]
  of SDL_SCANCODE_F:         @[keyF]
  of SDL_SCANCODE_G:         @[keyG]
  of SDL_SCANCODE_H:         @[keyH]
  of SDL_SCANCODE_I:         @[keyI, spell2]
  of SDL_SCANCODE_J:         @[keyJ, spell1]
  of SDL_SCANCODE_K:         @[keyK, jump]
  of SDL_SCANCODE_L:         @[keyL, spell3]
  of SDL_SCANCODE_M:         @[keyM, m]
  of SDL_SCANCODE_N:         @[keyN, n]
  of SDL_SCANCODE_O:         @[keyO]
  of SDL_SCANCODE_P:         @[keyP]
  of SDL_SCANCODE_Q:         @[keyQ]
  of SDL_SCANCODE_R:         @[keyR, restart]
  of SDL_SCANCODE_S:         @[keyS, down]
  of SDL_SCANCODE_T:         @[keyT]
  of SDL_SCANCODE_U:         @[keyU]
  of SDL_SCANCODE_V:         @[keyV, v]
  of SDL_SCANCODE_W:         @[keyW, up]
  of SDL_SCANCODE_X:         @[keyX, x]
  of SDL_SCANCODE_Y:         @[keyY]
  of SDL_SCANCODE_Z:         @[keyZ, z]

  else: @[]

proc mouseEventToButton(event: MouseButtonEventPtr): MouseButton =
  case event.button
  of 1:
    mouseLeft
  of 2:
    mouseMiddle
  of 3:
    mouseRight
  else:
    echo "Unexpected mouse button ", event.button, ", defaulting to left button"
    mouseLeft

proc isHeld*(manager: InputManager, key: Input): bool
proc update*(manager: var InputManager) =
  manager.bufferedEvents = @[]

  template updateInput(i) =
    if i == pressed:
      i = held
    elif i == released:
      i = inactive
  for i in Input:
    updateInput(manager.inputs[i])
  for b in MouseButton:
    updateInput(manager.mouseState[b])
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
    let inputs = keyToInputs e.key.keysym.scancode
    for input in inputs:
      if not (v == pressed and manager.inputs[input] == held):
        manager.inputs[input] = v
        manager.bufferedEvents.add InputEvent(
          kind: input,
          state: v,
          pos: manager.mousePos,
        )
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
      let
        pos = vec(event.button.x, event.button.y)
        button = mouseEventToButton event.button
      manager.mousePos = pos
      manager.mouseState[button] = pressed
    of MouseButtonUp:
      let button = mouseEventToButton event.button
      manager.mouseState[button] = released
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

proc isMousePressed*(manager: InputManager, button: MouseButton = mouseLeft): bool =
  manager.mouseState[button] == pressed

proc isMouseHeld*(manager: InputManager, button: MouseButton = mouseLeft): bool =
  ( manager.mouseState[button] == pressed or
    manager.mouseState[button] == held)

proc clickPressedPos*(manager: InputManager): Option[Vec] =
  if manager.isMousePressed:
    return makeJust(manager.mousePos)

proc clickHeldPos*(manager: InputManager): Option[Vec] =
  if manager.isMouseHeld:
    return makeJust(manager.mousePos)

proc clickReleasedPos*(manager: InputManager): Option[Vec] =
  if manager.mouseState[mouseLeft] == released:
    return makeJust(manager.mousePos)

proc mouseWheel*(manager: InputManager): int =
  manager.mouseWheel

proc getAxis*(manager: InputManager, axis: Axis): int =
  manager.axes[axis]

proc getEvents*(manager: InputManager): seq[InputEvent] =
  manager.bufferedEvents

const
  allLetters* = @[
    keyA, keyB, keyC, keyD, keyE,
    keyF, keyG, keyH, keyI, keyJ,
    keyK, keyL, keyM, keyN, keyO,
    keyP, keyQ, keyR, keyS, keyT,
    keyU, keyV, keyW, keyX, keyY,
    keyZ,
  ]
  allNumbers* = @[
    n0, n1, n2, n3, n4, n5, n6, n7, n8, n9
  ]

proc letterKeyStr*(button: Input): string =
  if button in allLetters:
    ($button)[3..4].toLowerAscii
  elif button in allNumbers:
    ($button)[1..2]
  else:
    ""

proc handleTextInput*(text: var string, input: InputManager, ignoreLetters = false): bool =
  # Returns true when text is modified
  template handleArray(arr: seq[Input]) =
    for key in arr:
      if input.isPressed(key):
        text &= key.letterKeyStr
        result = true
  if not ignoreLetters:
    handleArray(allLetters)
  handleArray(allNumbers)
  if input.isPressed(Input.backspace):
    text = text[0..<text.len-1]
    result = true
  if input.isPressed(Input.delete):
    text = ""
    result = true
