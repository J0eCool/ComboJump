import
  sdl2,
  sdl2.ttf

import
  game,
  input,
  util,
  vec

proc main =
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  defer: sdl2.quit()

  ttf.ttfInit()
  defer: ttf.ttfQuit()

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

  var dt = 1 / 60
  var game = newGame()
  while game.isRunning:
    game.update(dt)

    renderer.draw(game)

main()
