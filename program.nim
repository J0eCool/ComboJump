import
  random,
  sdl2,
  sdl2.image,
  sdl2.ttf,
  times

import
  input,
  menu,
  util,
  vec

type Program* = ref object of RootObj
  input*: InputManager
  menus*: MenuManager
  title*: string
  shouldExit*: bool
  frameTime*: float

proc initProgram*(program: Program) =
  program.input = newInputManager()
  program.menus = newMenuManager()

method init*(program: Program) {.base.} =
  discard

method update*(program: Program, dt: float) {.base.} =
  discard

method draw*(renderer: RendererPtr, program: Program) {.base.} =
  discard

proc updateBase(program: Program, dt: float) =
  program.input.update()
  if program.input.isPressed(Input.quit):
    program.shouldExit = true

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

  discard image.init()
  defer: image.quit()

  let
    window = createWindow(
      title = program.title,
      x = SDL_WINDOWPOS_CENTERED,
      y = SDL_WINDOWPOS_CENTERED,
      w = screenSize.x.cint,
      h = screenSize.y.cint,
      flags = SDL_WINDOW_SHOWN,
    )
  defer: window.destroy()

  let renderer = window.createRenderer(
    index = -1,
    flags = Renderer_Accelerated,
  )
  defer: renderer.destroy()

  program.init()

  const
    frames = 64
    maxFramerate = 60
    maxFrameTicks = ((1.0 / maxFramerate) * 1000).uint32
  var
    lastTime = getTicks()
    dt = 0.0
    pastFrames: array[frames, float]
    frameIdx = 0
  while (not program.shouldExit):
    let curTime = getTicks()
    dt = (curTime - lastTime).float / 1000.0
    lastTime = curTime.uint32

    program.updateBase(dt)
    renderer.drawBase(program)

    let
      updateTicks = getTicks() - curTime

    pastFrames[frameIdx] = updateTicks.float
    frameIdx = (frameIdx + 1) mod frames
    var sum = 0.0
    for t in pastFrames:
      sum += t
    program.frameTime = sum / frames

    let delayTicks = max(
      maxFrameTicks.int - updateTicks.int,
      0).uint32
    delay(delayTicks)
