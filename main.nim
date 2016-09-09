import math, sdl2

import game_object, input, util, vec

type Game = ref object
  input: InputManager
  renderer: RendererPtr
  isRunning: bool

proc newGame(renderer: RendererPtr): Game =
  Game(
    input: newInputManager(),
    renderer: renderer,
    isRunning: true,
  )

proc mainLoop(game: Game) =
  var t = 0.0
  var dt = 1 / 60
  var spd = 100.0
  let player = newGameObject(vec(500, 500), vec(80, 120), game.renderer)
  while game.isRunning:
    game.input.update()
    if game.input.isPressed(Input.exit):
      game.isRunning = false
    var dx = 0.0
    if game.input.isHeld(Input.left):
      dx -= spd * dt
    if game.input.isHeld(Input.right):
      dx += spd * dt
    player.move(vec(dx, 0))

    let render: RendererPtr = game.renderer
    var r = rect(cint(400 + 200 * sin(t)), 20, 100, 100)
    render.setDrawColor(110, 132, 174)
    render.clear()

    render.setDrawColor(64, 212, 110)
    render.fillRect(r)

    player.draw()

    render.present()
    t += dt

proc main =
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  defer: sdl2.quit()

  let window = createWindow(
    title = "2d tututuru",
    x = SDL_WINDOWPOS_CENTERED,
    y = SDL_WINDOWPOS_CENTERED,
    w = 1200,
    h = 900,
    flags = SDL_WINDOW_SHOWN,
  )
  defer: window.destroy()

  let renderer = window.createRenderer(
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync,
  )
  defer: renderer.destroy()

  var game = newGame(renderer)
  game.mainLoop()

main()
