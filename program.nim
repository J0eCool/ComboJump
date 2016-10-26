import
  random,
  sdl2,
  sdl2.ttf,
  times

import
  input,
  util,
  vec

type Program* = ref object of RootObj
  input*: InputManager
  shouldExit*: bool

proc initProgram*(program: Program) =
  program.input = newInputManager()

method init*(program: Program) {.base.} =
  discard

method update*(program: Program, dt: float) {.base.} =
  discard

method draw*(renderer: RendererPtr, program: Program) {.base.} =
  discard

proc updateBase(program: Program, dt: float) =
  program.input.update()
  if program.input.isPressed(Input.exit):
    program.shouldExit = true
    return

  program.update(dt)

proc drawBase(renderer: RendererPtr, program: Program) =
  renderer.setDrawColor(110, 132, 174)
  renderer.clear()

  renderer.draw(program)

  renderer.present()

proc main*(program: Program, screenSize: Vec) =
  randomize()

  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  defer: sdl2.quit()

  ttf.ttfInit()
  defer: ttf.ttfQuit()

  let
    window = createWindow(
      title = "2d tututuru",
      x = SDL_WINDOWPOS_CENTERED,
      y = SDL_WINDOWPOS_CENTERED,
      w = screenSize.x.cint,
      h = screenSize.y.cint,
      flags = SDL_WINDOW_SHOWN,
    )
  defer: window.destroy()

  let renderer = window.createRenderer(
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync,
  )
  defer: renderer.destroy()

  program.init()

  var dt = 1 / 60
  while (not program.shouldExit):
    program.updateBase(dt)

    renderer.drawBase(program)
