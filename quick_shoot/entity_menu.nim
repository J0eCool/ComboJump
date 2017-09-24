from sdl2 import RendererPtr

import
  component/[
    collider,
    damage_component,
    enemy_attack,
    enemy_shooter_movement,
    enemy_proximity,
    enemy_stats,
    grid_control,
    health,
    health_bar,
    hud_menu,
    limited_quantity,
    locked_door,
    mana,
    movement,
    player_health,
    progress_bar,
    sprite,
    text,
    transform,
  ],
  system/[
    bullet_update,
    physics,
    render,
  ],
  camera,
  color,
  event,
  input,
  menu,
  entity,
  resources,
  transition,
  vec

type
  EntityModel = ref object of RootObj
    entities: Entities
    spawnTimer: float
  EntityController = ref object of Controller
    bufferClose: bool

proc newEntityModel(): EntityModel =
  EntityModel(entities: @[
    newEntity("Player", [
      Transform(pos: vec(300, 300), size: vec(80, 36)),
      Movement(),
      Collider(layer: Layer.player),
      Sprite(textureName: "Ship.png"),
      GridControl(
        moveSpeed: 300,
        followMouse: true,
      ),
    ]),
    newEntity("Enemy", [
      Transform(pos: vec(800, 500), size: vec(50, 50)),
      Movement(),
      Collider(layer: Layer.enemy),
      Sprite(textureName: "Goblin.png"),
      EnemyAttack(
        damage: 1,
        size: 25,
        attackSpeed: 1.2,
        bulletSpeed: 400,
        attackDir: vec(-1, 0),
      ),
      # EnemyProximity(),
    ]),
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

  template ents: Entities = model.entities
  discard gridControl(ents, dt, input)
  discard updateEnemyShooterMovement(ents, dt)
  process(ents, updateEnemyAttack(ents, dt))
  process(ents, updateBullets(ents, dt))

  discard physics(model.entities, dt)

type EntityRenderNode = ref object of Node
  entities: Entities

method drawSelf(node: EntityRenderNode, renderer: RendererPtr, resources: var ResourceManager) =
  let camera = Camera()
  loadResources(node.entities, resources, renderer)
  renderer.renderSystem(node.entities, camera)

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
