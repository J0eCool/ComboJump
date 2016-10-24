import
  sdl2,
  sdl2.ttf

import
  input,
  util,
  vec

type Program* = ref object of RootObj
  shouldExit*: bool

method update*(program: Program, dt: float) {.base.} =
  discard

method draw*(renderer: RendererPtr, program: Program) {.base.} =
  discard

proc main*(program: Program, screenSize: Vec) =
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

  var dt = 1 / 60
  while (not program.shouldExit):
    program.update(dt)

    renderer.draw(program)

