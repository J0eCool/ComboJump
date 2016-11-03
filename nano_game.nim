import math, macros, sdl2

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  game,
  component/camera_target,
  component/collider,
  component/health,
  component/mana,
  component/movement,
  component/player_control,
  component/progress_bar,
  component/sprite,
  component/text,
  component/transform,
  system/collisions,
  system/physics,
  system/player_input,
  system/player_movement,
  system/quantity_regen,
  system/render,
  system/update_progress_bar,
  camera,
  entity,
  event,
  input,
  program,
  resources,
  vec,
  util

type NanoGame* = ref object of Game

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"

method loadEntities*(game: NanoGame) =
  game.entities = @[
    newEntity("Player", [
      Transform(pos: vec(180, 500),
                size: vec(50, 75)),
      Movement(usesGravity: true),
      newMana(100),
      PlayerControl(),
      Sprite(color: color(12, 255, 12, 255)),
      Collider(layer: Layer.player),
      CameraTarget(),
    ]),
    newEntity("Ground", [
      Transform(pos: vec(1450, 810),
                size: vec(2900, 40)),
      Sprite(color: color(192, 192, 192, 255)),
      Collider(layer: Layer.floor),
    ]),
    newEntity("Platform", [
      Transform(pos: vec(1200, 600),
                size: vec(350, 35)),
      Sprite(color: color(192, 192, 192, 255)),
      Collider(layer: Layer.floor),
    ]),
    newEntity("RightPlatform", [
      Transform(pos: vec(2200, 600),
                size: vec(350, 35)),
      Sprite(color: color(192, 192, 192, 255)),
      Collider(layer: Layer.floor),
    ]),
    newEntity("PlayerManaBarBG", [
      Transform(pos: vec(100, 200),
                size: vec(310, 50)),
      Sprite(color: color(32, 32, 32, 255)),
    ], children=[
      newEntity("PlayerManaBar", [
        Transform(pos: vec(0),
                  size: vec(300, 40)),
        Sprite(color: color(32, 32, 255, 255)),
        newProgressBar("Player",
                       heldTarget="PlayerManaBarHeld",
                       textEntity="PlayerManaBarText"),
      ]),
      newEntity("PlayerManaBarText", [
        Transform(pos: vec(0),
                  size: vec(0)),
        newText("999/999"),
      ]),
      newEntity("PlayerManaBarHeld", [
        Transform(pos: vec(0),
                  size: vec(300, 40)),
        Sprite(color: color(125, 232, 255, 255)),
      ]),
    ]),
  ]

method update*(game: Game, dt: float) =
  if game.input.isPressed(Input.restart):
    let input = game.input
    game.loadEntities()
    game.input = input

  game.processAll game.entities:
    playerInput(game.input)
    playerMovement(dt)

    physics(dt)
    checkCollisisons()
    updateCamera(game.camera)
    
    regenLimitedQuantities(dt)

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
