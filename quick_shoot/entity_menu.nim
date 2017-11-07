from sdl2 import RendererPtr

import
  component/[
    collider,
    damage_component,
    enemy_attack,
    enemy_shooter_movement,
    grid_control,
    health,
    movement,
    player_shooter_attack,
    remove_when_offscreen,
    shooter_reward_on_death,
    sprite,
    transform,
  ],
  quick_shoot/[
    level,
    shooter_stats,
    weapon,
  ],
  system/[
    bullet_update,
    collisions,
    physics,
  ],
  camera,
  color,
  event,
  game_system,
  input,
  menu,
  menu_widgets,
  entity,
  notifications,
  resources,
  transition,
  util,
  vec

# Imported last because of system rebuild determinism
import menu/entity_render_node

const buildDebugMenu = false
when buildDebugMenu:
  import
    sdl2,
    sdl2.ttf,
    strutils,
    times

type
  EntityModel = ref object of RootObj
    entities: Entities
    dt: float
    input: InputManager
    camera: Camera
    timer: float
    player: Entity
    stats: ShooterStats
    level: Level
    notifications: N10nManager

  EntityController = ref object of Controller
    when buildDebugMenu:
      window: WindowPtr
      renderer: RendererPtr
      resources: ResourceManager

proc process(model: EntityModel, events: Events) =
  model.entities.process(events)

defineSystemCalls(EntityModel)

proc newEntityModel(stats: ShooterStats, levelInfo: LevelInfo): EntityModel =
  let player = newEntity("Player", [
    Transform(pos: vec(300, 300), size: vec(80, 36)),
    Movement(),
    newHealth(stats.maxHealth),
    Collider(layer: Layer.player),
    Sprite(textureName: "Ship.png"),
    GridControl(
      moveSpeed: 300,
      followMouse: true,
    ),
    PlayerShooterAttack(
      shotOffset: vec(30, 3),
      ammo: stats.maxAmmo,
    ),
  ])
  stats.resetWeapons()
  EntityModel(
    entities: @[player],
    player: player,
    camera: Camera(screenSize: vec(1200, 900)),
    notifications: newN10nManager(),
    stats: stats,
    level: levelInfo.toLevel(),
  )

proc newEntityController(): EntityController =
  result = EntityController()
  when buildDebugMenu:
    result.window = createWindow(
      title = "DEBUG WINDOW",
      x = SDL_WINDOWPOS_CENTERED,
      y = SDL_WINDOWPOS_CENTERED,
      w = 600,
      h = 900,
      flags = SDL_WINDOW_SHOWN,
    )
    result.renderer = result.window.createRenderer(
      index = -1,
      flags = Renderer_Accelerated,
    )
    result.resources = newResourceManager()

proc closeEntityMenu(controller: EntityController) =
  controller.shouldPop = true
  controller.queueMenu downcast(newFadeOnlyOut())

  when buildDebugMenu:
    controller.window.destroy()
    controller.renderer.destroy()

proc entityModelUpdate(model: EntityModel, controller: EntityController,
                       dt: float, input: InputManager) {.procvar.} =
  for enemy in model.level.toSpawn(model.timer, model.timer + dt):
    model.entities.add enemy
  model.timer += dt

  model.dt = dt
  model.input = input
  model.updateSystems()
  if model.player.getComponent(Health).cur <= 0:
    controller.closeEntityMenu()

  var enemiesLeft = false
  for e in model.entities:
    let col = e.getComponent(Collider)
    if col != nil and col.layer == Layer.enemy:
      enemiesLeft = true
      break
  if model.level.isDoneSpawning(model.timer - 2.5) and (not enemiesLeft):
    controller.closeEntityMenu()

  when buildDebugMenu:
    let renderer = controller.renderer
    renderer.setDrawColor(128, 128, 128)
    renderer.clear()

    var strs: seq[string] = @[]
    for e in model.entities:
      strs &= e.debugStr.split("\n")
    let node = stringListNode(strs, vec(300, 30), 14)
    renderer.draw(node, controller.resources)

    renderer.present()

proc entityModelView(model: EntityModel, controller: EntityController): Node {.procvar.} =
  let
    health = model.player.getComponent(Health)
    attack = model.player.getComponent(PlayerShooterAttack)
  nodes(@[
    SpriteNode(
      size: vec(2400, 2400),
      pos: vec(1200, 1200),
      color: rgb(8, 16, 32),
    ),
    EntityRenderNode(entities: model.entities),
    Button(
      pos: vec(1100, 100),
      size: vec(80, 50),
      label: "Exit",
      hotkey: Input.escape,
      onClick: (proc() =
        controller.closeEntityMenu()
      ),
    ),
    BorderedTextNode(
      pos: vec(200, 700),
      text: "G: " & $model.stats.gold,
    ),
    BorderedTextNode(
      pos: vec(600, 100),
      text: model.level.info.name,
    ),
    quantityBarNode(
      health.cur.int,
      health.max.int,
      vec(220, 50),
      vec(400, 30),
      red,
    ),
    quantityBarNode(
      attack.ammo,
      model.stats.maxAmmo,
      vec(220, 90),
      vec(340, 25),
      yellow,
    )
  ])

proc newEntityMenu*(stats: ShooterStats, level: LevelInfo): Menu[EntityModel, EntityController] =
  Menu[EntityModel, EntityController](
    model: newEntityModel(stats, level),
    view: entityModelView,
    update: entityModelUpdate,
    controller: newEntityController(),
  )
