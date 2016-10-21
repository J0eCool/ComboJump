import math, macros, sdl2

const Profile {.intdefine.}: int = 0
when Profile != 0:
  import nimprof

import
  component/bullet,
  component/camera_target,
  component/clickable,
  component/collider,
  component/enemy_movement,
  component/health,
  component/mana,
  component/movement,
  component/player_control,
  component/progress_bar,
  component/sprite,
  component/text,
  component/transform,
  system/bullet_hit,
  system/bullet_update,
  system/collisions,
  system/physics,
  system/player_input,
  system/player_movement,
  system/player_shoot,
  system/quantity_regen,
  system/render,
  system/update_progress_bar,
  camera,
  entity,
  event,
  input,
  vec,
  util

type Game = ref object
  input: InputManager
  resources: ResourceManager
  isRunning*: bool
  entities: seq[Entity]
  camera: Camera

proc newGame*(screenSize: Vec): Game =
  result = Game(
    input: newInputManager(),
    resources: newResourceManager(),
    isRunning: true,
    entities: @[
      newEntity("Player", [
        Transform(pos: vec(180, 500),
                  size: vec(50, 75)),
        Movement(usesGravity: true),
        newMana(100),
        PlayerControl(),
        Sprite(color: color(12, 255, 12, 255)),
        Collider(layer: Layer.player),
        Clickable(),
        CameraTarget(),
      ]),
      newEntity("Enemy", [
        Transform(pos: vec(600, 400),
                  size: vec(60, 60)),
        Movement(usesGravity: true),
        newHealth(20),
        Sprite(color: color(155, 16, 24, 255)),
        Collider(layer: Layer.enemy),
        EnemyMovement(targetRange: 400, moveSpeed: 200),
      ]),
      newEntity("Enemy2", [
        Transform(pos: vec(1000, 500),
                  size: vec(60, 60)),
        Movement(usesGravity: true),
        newHealth(20),
        Sprite(color: color(155, 16, 24, 255)),
        Collider(layer: Layer.enemy),
      ]),
      newEntity("Ground", [
        Transform(pos: vec(50, 800),
                  size: vec(2900, 35)),
        Sprite(color: color(192, 192, 192, 255)),
        Collider(layer: Layer.floor),
      ]),
      newEntity("LeftWall", [
        Transform(pos: vec(50, 465),
                  size: vec(35, 350)),
        Sprite(color: color(192, 192, 192, 255)),
        Collider(layer: Layer.floor),
      ]),
      newEntity("RightWall", [
        Transform(pos: vec(2865, 465),
                  size: vec(35, 350)),
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
          Transform(pos: vec(5, 5),
                    size: vec(300, 40)),
          Sprite(color: color(32, 32, 255, 255)),
          newProgressBar("Player",
                         heldTarget="PlayerManaBarHeld",
                         textEntity="PlayerManaBarText"),
        ]),
        newEntity("PlayerManaBarText", [
          Transform(pos: vec(50, 10),
                    size: vec(0)),
          newText("999/999"),
        ]),
        newEntity("PlayerManaBarHeld", [
          Transform(pos: vec(5, 5),
                    size: vec(300, 40)),
          Sprite(color: color(125, 232, 255, 255)),
        ]),
      ]),
      newEntity("EnemyHealthBarBG", [
        Transform(pos: vec(800, 200),
                  size: vec(310, 50)),
        Sprite(color: color(32, 32, 32, 255)),
      ], children=[
        newEntity("EnemyHealthBar", [
          Transform(pos: vec(5, 5),
                    size: vec(300, 40)),
          Sprite(color: color(255, 32, 32, 255)),
          newProgressBar("Enemy"),
        ]),
      ]),
    ],
  )
  result.camera.screenSize = screenSize

proc process(game: var Game, events: Events) =
  for event in events:
    case event.kind
    of addEntity:
      game.entities.add event.entity
    of removeEntity:
      game.entities.remove event.entity

macro processAll(game, entities: expr, body: untyped): stmt =
  result = newNimNode(nnkStmtList)
  for node in body:
    let callNode = newCall(node[0], entities)
    for i in 1..<node.len:
      callNode.add node[i]
    result.add(newCall(!"process", game, callNode))

proc draw*(render: RendererPtr, game: Game) =
  game.entities.updateProgressBars()

  game.entities.loadResources(game.resources)

  render.setDrawColor(110, 132, 174)
  render.clear()

  game.entities.renderSystem(render, game.camera)

  render.present()

proc update*(game: var Game, dt: float) =
  game.input.update()
  if game.input.isPressed(Input.exit):
    game.isRunning = false
  if game.input.isPressed(Input.restart):
    let input = game.input
    game = newGame(game.camera.screenSize)
    game.input = input

  game.processAll game.entities:
    updateClicked(game.input)

    playerInput(game.input)
    playerMovement(dt)

    physics(dt)
    checkCollisisons()
    updateCamera(game.camera)
    
    regenLimitedQuantities(dt)

    updateBullets(dt)
    updateBulletDamage()
    updateFieryBullets(dt)
    
    playerShoot(dt)
    clickPlayer()

    updateEnemyMovement(dt)
