import math, macros, sdl2

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  system/render,
  camera,
  entity,
  event,
  gun,
  input,
  prefabs,
  program,
  resources,
  scrolling_background,
  system,
  vec,
  util

type NanoGame* = ref object of Game
  background: ScrollingBackground

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"
  result.background = newScrollingBackground()

method loadEntities*(game: NanoGame) =
  game.entities = @[
    newPlayer(vec(300, 400)),
    newEnemy(goblin, vec(600, 400)),
    newEnemy(ogre, vec(700, 100)),
  ]

importAllSystems()
defineSystemCalls(NanoGame)

method draw*(renderer: RendererPtr, game: NanoGame) =
  game.background.loadBackgroundAssets(game.resources, renderer)

  renderer.drawSystems(game)
  renderer.drawGame(game)

  renderer.drawCachedText($game.frameTime & "ms", vec(1100, 875),
                          game.resources.loadFont("nevis.ttf"), color(0, 0, 0, 255))

method update*(game: NanoGame, dt: float) =
  game.updateBase()
  game.dt = dt

  game.updateSystems()

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
