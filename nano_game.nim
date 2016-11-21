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
  component/health,
  component/limited_quantity,
  component/mana,
  component/movement,
  component/player_control,
  component/progress_bar,
  component/sprite,
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
  vec,
  util

type NanoGame* = ref object of Game

proc newNanoGame*(screenSize: Vec): NanoGame =
  new result
  result.camera.screenSize = screenSize
  result.title = "NaNo Game 2016"

method loadEntities*(game: NanoGame) =
  game.entities = @[
    # --- Actors ---
    newEntity("Player", [
      Transform(pos: vec(180, 500),
                size: vec(50, 75)),
      Movement(usesGravity: true),
      newHealth(30),
      newMana(100),
      PlayerControl(),
      PlayerShooting(
        spells: [
          createSpell((gun: projectileBase, runes: @[(base, 50.0)])),
          createSpell((gun: projectileBase, runes: @[(base, 50.0), (fiery, 30.0)])),
          createSpell((gun: projectileBase, runes: @[(base, 50.0), (spread, 30.0)])),
        ],
      ),
      Sprite(textureName: "Wizard.png"),
      Collider(layer: Layer.player),
      CameraTarget(),
    ]),
    newEntity("Enemy", [
      Transform(pos: vec(700, 400),
                size: vec(60, 60)),
      Movement(usesGravity: true),
      newHealth(20),
      Damage(damage: 1),
      Sprite(color: color(155, 16, 24, 255)),
      Collider(layer: Layer.enemy),
      EnemyMoveTowards(moveSpeed: 200),
      EnemyProximity(targetMinRange: 75, targetRange: 400),
    ]),
    newEntity("Jumping Enemy", [
      Transform(pos: vec(1200, 400),
                size: vec(60, 60)),
      Movement(usesGravity: true),
      newHealth(20),
      Sprite(color: color(155, 16, 124, 255)),
      Collider(layer: Layer.enemy),
      EnemyJumpTowards(moveSpeed: 250, jumpHeight: 115, jumpDelay: 0.5),
      EnemyProximity(targetRange: 400),
    ]),

    # --- Terrain ---
    newEntity("Ground", [
      Transform(pos: vec(1450, 810),
                size: vec(2900, 40)),
      Sprite(color: color(192, 192, 192, 255)),
      Collider(layer: Layer.floor),
    ]),
    newEntity("LeftWall", [
      Transform(pos: vec(-20, 610),
                size: vec(40, 440)),
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

    # --- UI ---
    newEntity("PlayerHealthBarBG", [
      Transform(pos: vec(200, 60),
                size: vec(310, 35)),
      Sprite(color: color(32, 32, 32, 255),
             ignoresCamera: true),
    ], children=[
      newEntity("PlayerHealthBar", [
        Transform(pos: vec(0),
                  size: vec(300, 25)),
        Sprite(color: color(255, 32, 32, 255),
               ignoresCamera: true),
        newProgressBar[Health](
          "Player",
          textEntity="PlayerHealthBarText"),
      ]),
      newEntity("PlayerHealthBarText", [
        Transform(pos: vec(0),
                  size: vec(0)),
        newText("999/999"),
      ]),
    ]),
    newEntity("PlayerManaBarBG", [
      Transform(pos: vec(200, 90),
                size: vec(310, 35)),
      Sprite(color: color(32, 32, 32, 255),
             ignoresCamera: true),
    ], children=[
      newEntity("PlayerManaBar", [
        Transform(pos: vec(0),
                  size: vec(300, 25)),
        Sprite(color: color(32, 32, 255, 255),
               ignoresCamera: true),
        newProgressBar[Mana](
          "Player",
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
                  size: vec(300, 25)),
        Sprite(color: color(125, 232, 255, 255),
               ignoresCamera: true),
      ]),
    ]),
  ]

method draw*(renderer: RendererPtr, game: NanoGame) =
  renderer.drawGame(game)

  renderer.drawCachedText($game.frameTime & "ms", vec(1100, 875),
                          game.resources.loadFont("nevis.ttf"), color(0, 0, 0, 255))

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newNanoGame(screenSize), screenSize)
