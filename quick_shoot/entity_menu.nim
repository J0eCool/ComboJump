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
    sprite,
    transform,
  ],
  quick_shoot/[
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
  entity,
  notifications,
  resources,
  transition,
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
    notifications: N10nManager
  EntityController = ref object of Controller
    bufferClose: bool

proc process(model: EntityModel, events: Events) =
  model.entities.process(events)

defineSystemCalls(EntityModel)

proc newEntityModel(): EntityModel =
  let player = newEntity("Player", [
    Transform(pos: vec(300, 300), size: vec(80, 36)),
    Movement(),
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
    stats: ShooterStats(
      attackSpeed: 1.4,
      damage: 3,
      numBullets: 1,
    ),
  )

proc spawnEnemy(model: EntityModel) =
  model.entities.add newEntity("Goblin", [
    Transform(pos: vec(1000, -100), size: vec(50, 50)),
    Movement(),
    Collider(layer: Layer.enemy),
    Sprite(textureName: "Goblin.png"),
    newHealth(8),
    EnemyAttack(
      damage: 1,
      size: 25,
      attackSpeed: 1.2,
      bulletSpeed: 400,
      attackDir: vec(-1, 0),
    ),
    EnemyShooterMovement(moveSpeed: 120),
    RemoveWhenOffscreen(buffer: 100),
  ])

method pushMenus(controller: EntityController): seq[MenuBase] =
  if controller.bufferClose:
    result = @[downcast(newFadeOnlyOut())]

proc entityModelUpdate(model: EntityModel, controller: EntityController,
                       dt: float, input: InputManager) {.procvar.} =
  if controller.bufferClose:
    controller.bufferClose = false
    controller.shouldPop = true
    return

  model.spawnTimer += dt
  let timeToSpawn = 1.5
  if model.spawnTimer >= timeToSpawn:
    model.spawnTimer -= timeToSpawn
    model.spawnEnemy()

  model.dt = dt
  model.input = input
  model.updateSystems()

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
        controller.bufferClose = true
      ),
    ),
  ])

proc newEntityMenu*(): Menu[EntityModel, EntityController] =
  Menu[EntityModel, EntityController](
    model: newEntityModel(),
    view: entityModelView,
    update: entityModelUpdate,
    controller: EntityController(),
  )
