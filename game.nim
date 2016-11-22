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
  system/render,
  system/update_progress_bar,
  camera,
  entity,
  event,
  input,
  program,
  resources,
  system,
  vec,
  util

type Game* = ref object of Program
  resources*: ResourceManager
  entities*: Entities
  camera*: Camera
  dt*: float

method loadEntities*(game: Game) {.base.}

proc newGame*(screenSize: Vec): Game =
  new result
  result.title = "WizGame"
  result.camera.screenSize = screenSize

method init*(game: Game) =
  game.initProgram()
  game.resources = newResourceManager()
  game.loadEntities()

method loadEntities*(game: Game) =
  discard
  # normalSpell = createSpell(
  #   (projectileBase,
  #     @[(damage, 100.0),
  #       (fiery, 50.0)]
  #   ),
  #   (projectileBase,
  #     @[(damage, 40.0),
  #       (spread, 60.0)]
  #   ),
  # )
  # spreadSpell = createSpell(
  #   (projectileBase,
  #     @[(damage, 40.0),
  #       (spread, 60.0)]
  #   ),
  #   (projectileBase,
  #     @[(damage, 40.0),
  #       (spread, 60.0)]
  #   ),
  # )
  # homingSpell = createSpell(
  #   (projectileBase,
  #     @[(damage, 20.0),
  #       (spread, 40.0),
  #       (homing, 40.0),
  #       (fiery, 20.0)]
  #   ),
  # )
  # spells = [normalSpell, spreadSpell, homingSpell]

  # game.entities = @[
  #   newEntity("Player", [
  #     Transform(pos: vec(180, 500),
  #               size: vec(50, 75)),
  #     Movement(usesGravity: true),
  #     newMana(100),
  #     PlayerControl(),
  #     Sprite(color: color(12, 255, 12, 255)),
  #     Collider(layer: Layer.player),
  #     Clickable(),
  #     CameraTarget(),
  #   ]),
  #   newEntity("Enemy", [
  #     Transform(pos: vec(600, 400),
  #               size: vec(60, 60)),
  #     Movement(usesGravity: true),
  #     newHealth(20),
  #     Sprite(color: color(155, 16, 24, 255)),
  #     Collider(layer: Layer.enemy),
  #     EnemyMovement(targetRange: 400, moveSpeed: 200),
  #   ]),
  #   newEntity("Enemy2", [
  #     Transform(pos: vec(1000, 500),
  #               size: vec(60, 60)),
  #     Movement(usesGravity: true),
  #     newHealth(20),
  #     Sprite(color: color(155, 16, 24, 255)),
  #     Collider(layer: Layer.enemy),
  #   ]),
  #   newEntity("Ground", [
  #     Transform(pos: vec(1450, 810),
  #               size: vec(2900, 40)),
  #     Sprite(color: color(192, 192, 192, 255)),
  #     Collider(layer: Layer.floor),
  #   ]),
  #   newEntity("LeftWall", [
  #     Transform(pos: vec(20, 620),
  #               size: vec(40, 340)),
  #     Sprite(color: color(192, 192, 192, 255)),
  #     Collider(layer: Layer.floor),
  #   ]),
  #   newEntity("RightWall", [
  #     Transform(pos: vec(2880, 620),
  #               size: vec(40, 340)),
  #     Sprite(color: color(192, 192, 192, 255)),
  #     Collider(layer: Layer.floor),
  #   ]),
  #   newEntity("Platform", [
  #     Transform(pos: vec(1200, 600),
  #               size: vec(350, 35)),
  #     Sprite(color: color(192, 192, 192, 255)),
  #     Collider(layer: Layer.floor),
  #   ]),
  #   newEntity("RightPlatform", [
  #     Transform(pos: vec(2200, 600),
  #               size: vec(350, 35)),
  #     Sprite(color: color(192, 192, 192, 255)),
  #     Collider(layer: Layer.floor),
  #   ]),
  #   newEntity("PlayerManaBarBG", [
  #     Transform(pos: vec(100, 200),
  #               size: vec(310, 50)),
  #     Sprite(color: color(32, 32, 32, 255)),
  #   ], children=[
  #     newEntity("PlayerManaBar", [
  #       Transform(pos: vec(0),
  #                 size: vec(300, 40)),
  #       Sprite(color: color(32, 32, 255, 255)),
  #       newProgressBar("Player",
  #                      heldTarget="PlayerManaBarHeld",
  #                      textEntity="PlayerManaBarText"),
  #     ]),
  #     newEntity("PlayerManaBarText", [
  #       Transform(pos: vec(0),
  #                 size: vec(0)),
  #       newText("999/999"),
  #     ]),
  #     newEntity("PlayerManaBarHeld", [
  #       Transform(pos: vec(0),
  #                 size: vec(300, 40)),
  #       Sprite(color: color(125, 232, 255, 255)),
  #     ]),
  #   ]),
  #   newEntity("EnemyHealthBarBG", [
  #     Transform(pos: vec(800, 200),
  #               size: vec(310, 50)),
  #     Sprite(color: color(32, 32, 32, 255)),
  #   ], children=[
  #     newEntity("EnemyHealthBar", [
  #       Transform(pos: vec(0),
  #                 size: vec(300, 40)),
  #       Sprite(color: color(255, 32, 32, 255)),
  #       newProgressBar("Enemy"),
  #     ]),
  #   ]),
  # ]

proc process*(game: Game, events: Events) =
  for event in events:
    case event.kind
    of addEntity:
      game.entities.add event.entity
    of removeEntity:
      game.entities.remove event.entity

proc drawGame*(renderer: RendererPtr, game: Game) =
  game.entities.updateProgressBars()

  game.entities.loadResources(game.resources, renderer)

  game.entities.renderSystem(renderer, game.camera)

method draw*(renderer: RendererPtr, game: Game) =
  renderer.drawGame(game)

proc updateBase*(game: Game) =
  if game.input.isPressed(Input.restart):
    let input = game.input
    game.loadEntities()
    game.input = input

importAllSystems()
defineSystemCalls(Game)
method update*(game: Game, dt: float) =
  game.updateBase()
  game.dt = dt

  game.updateSystems()

when isMainModule:
  let screenSize = vec(1200, 900)
  main(newGame(screenSize), screenSize)
