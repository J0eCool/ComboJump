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
    notifications: N10nManager
  EntityController = ref object of Controller

proc process(model: EntityModel, events: Events) =
  model.entities.process(events)

defineSystemCalls(EntityModel)

proc newEntityModel(stats: ShooterStats): EntityModel =
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
  )

proc spawnEnemy(model: EntityModel) =
  let
    moveKind = random[EnemyShooterMovementKind]()
    pos =
      case moveKind
      of moveDown:
        vec(1000, -100)
      of moveUp:
        vec(1000, 1000)
  model.entities.add newEntity("Goblin", [
    Transform(pos: pos, size: vec(50, 50)),
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
    EnemyShooterMovement(
      kind: moveKind,
      moveSpeed: 120,
    ),
    RemoveWhenOffscreen(buffer: 100),
    ShooterRewardOnDeath(
      xp: 3,
      gold: 2,
    ),
  ])


proc entityModelUpdate(model: EntityModel, controller: EntityController,
                       dt: float, input: InputManager) {.procvar.} =
  model.spawnTimer += dt
  let timeToSpawn = 1.5
  if model.spawnTimer >= timeToSpawn:
    model.spawnTimer -= timeToSpawn
    model.spawnEnemy()

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
    quantityBarNode(
      health.cur.int,
      health.max.int,
      vec(220, 50),
      vec(400, 30),
      red,
    ),
  ])

proc newEntityMenu*(stats: ShooterStats): Menu[EntityModel, EntityController] =
  Menu[EntityModel, EntityController](
    model: newEntityModel(stats),
    view: entityModelView,
    update: entityModelUpdate,
    controller: EntityController(),
  )
