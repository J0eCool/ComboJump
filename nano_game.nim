import math, macros, sdl2

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  component/camera_target,
  component/collider,
  component/damage,
  component/enemy_movement,
  component/grid_control,
  component/health,
  component/limited_quantity,
  component/mana,
  component/movement,
  component/player_control,
  component/progress_bar,
  component/sprite,
  component/target_shooter,
  component/text,
  component/transform,
  system/render,
  camera,
  entity,
  event,
  gun,
  input,
  program,
  resources,
  scrolling_background,
  system,
  targeting,
  vec,
  util

type NanoGame* = ref object of Game
  background: ScrollingBackground
  targeting: Targeting

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"
  result.background = newScrollingBackground()

method loadEntities*(game: NanoGame) =
  game.entities = @[
    newEntity("Player", [
      Transform(pos: vec(300, 400),
                size: vec(76, 68)),
      Movement(),
      Collider(layer: player),
      GridControl(moveSpeed: 300.0),
      CameraTarget(vertical: true),
      TargetShooter(),
      Sprite(textureName: "Wizard2.png"),
    ]),
    newEntity("Goblin", [
      Transform(pos: vec(600, 400),
                size: vec(48, 56)),
      Movement(),
      newHealth(20),
      Collider(layer: enemy),
      Sprite(textureName: "Goblin.png"),
    ]),
    newEntity("Ogre", [
      Transform(pos: vec(700, 100),
                size: vec(52, 80)),
      Movement(),
      newHealth(40),
      Collider(layer: enemy),
      Sprite(textureName: "Ogre.png"),
    ]),
    newEntity("Block", [
      Transform(pos: vec(500, 700),
                size: vec(60, 60)),
      Collider(layer: Layer.floor),
      Sprite(color: color(140, 140, 140, 255)),
    ]),
  ]

method draw*(renderer: RendererPtr, game: NanoGame) =
  game.background.loadBackgroundAssets(game.resources, renderer)
  renderer.draw(game.background, game.camera)
  renderer.draw(game.targeting, game.camera)

  renderer.drawGame(game)

  renderer.drawCachedText($game.frameTime & "ms", vec(1100, 875),
                          game.resources.loadFont("nevis.ttf"), color(0, 0, 0, 255))

importAllSystems()
defineSystemCalls(NanoGame)
method update*(game: NanoGame, dt: float) =
  game.updateBase()
  game.dt = dt

  game.updateSystems()

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
