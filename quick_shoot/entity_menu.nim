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
  ],
  system/[
    bullet_update,
    collisions,
    physics,
    render,
  ],
  camera,
  color,
  game_system,
  event,
  input,
  menu,
  menu_widgets,
  entity,
  notifications,
  resources,
  transition,
  util,
  vec

type
  EntityModel = ref object of RootObj
    entities: Entities
    dt: float
    input: InputManager
    camera: Camera
    spawnTimer: float
    player: Entity
    stats: ShooterStats
    level: Level
    notifications: N10nManager
  EntityController = ref object of Controller

proc process(model: EntityModel, events: Events) =
  model.entities.process(events)

defineSystemCalls(EntityModel)

proc newEntityModel(stats: ShooterStats, level: Level): EntityModel =
  let player = newEntity("Player", [
    Transform(pos: vec(300, 300), size: vec(80, 36)),
    Movement(),
    newHealth(10),
    Collider(layer: Layer.player),
    Sprite(textureName: "Ship.png"),
    GridControl(
      moveSpeed: 300,
      followMouse: true,
    ),
    PlayerShooterAttack(),
  ])
  EntityModel(
    entities: @[player],
    player: player,
    camera: Camera(screenSize: vec(1200, 900)),
    notifications: newN10nManager(),
    stats: stats,
    level: level,
  )

proc entityModelUpdate(model: EntityModel, controller: EntityController,
                       dt: float, input: InputManager) {.procvar.} =
  for enemy in model.level.toSpawn(model.spawnTimer, model.spawnTimer + dt):
    model.entities.add enemy
  model.spawnTimer += dt

  model.dt = dt
  model.input = input
  model.updateSystems()
  if model.player.getComponent(Health).cur <= 0:
    controller.shouldPop = true
    controller.queueMenu downcast(newFadeOnlyOut())

type EntityRenderNode = ref object of Node
  entities: Entities
  resources: ResourceManager
  camera: Camera

proc process(node: EntityRenderNode, events: Events) =
  node.entities.process(events)

method diffSelf(node, newVal: EntityRenderNode) =
  node.entities = newVal.entities

defineSystemCalls(EntityRenderNode)

method drawSelf(node: EntityRenderNode, renderer: RendererPtr, resources: ResourceManager) =
  loadResources(node.entities, resources, renderer)
  node.resources = resources
  renderer.drawSystems(node)

proc entityModelView(model: EntityModel, controller: EntityController): Node {.procvar.} =
  let health = model.player.getComponent(Health)
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
      hotkey: escape,
      onClick: (proc() =
        controller.shouldPop = true
        controller.queueMenu downcast(newFadeOnlyOut())
      ),
    ),
    BorderedTextNode(
      pos: vec(200, 700),
      text: "G: " & $model.stats.gold,
    ),
    BorderedTextNode(
      pos: vec(600, 100),
      text: model.level.name,
    ),
    quantityBarNode(
      health.cur.int,
      health.max.int,
      vec(220, 50),
      vec(400, 30),
      red,
    ),
  ])

proc newEntityMenu*(stats: ShooterStats, level: Level): Menu[EntityModel, EntityController] =
  Menu[EntityModel, EntityController](
    model: newEntityModel(stats, level),
    view: entityModelView,
    update: entityModelUpdate,
    controller: EntityController(),
  )
