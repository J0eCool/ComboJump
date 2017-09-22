from sdl2 import RendererPtr

import
  component/[
    collider,
    damage_component,
    enemy_attack,
    enemy_movement,
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
    physics,
    render,
  ],
  camera,
  input,
  menu,
  entity,
  resources,
  transition,
  vec


type
  EntityModel = ref object of RootObj
    entities: Entities
    t: float
  EntityController = ref object of Controller
    bufferClose: bool

proc newEntityModel(): EntityModel =
  EntityModel(entities: @[
    newEntity("Player", [
      Transform(pos: vec(300, 300), size: vec(48, 28)),
      Movement(),
      Collider(layer: Layer.player),
      Sprite(textureName: "Goblin.png"),
      GridControl(
        moveSpeed: 300,
        followMouse: true,
      ),
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

  discard gridControl(model.entities, dt, input)
  discard physics(model.entities, dt)

type EntityRenderNode = ref object of Node
  entities: Entities

method drawSelf(node: EntityRenderNode, renderer: RendererPtr, resources: var ResourceManager) =
  let camera = Camera()
  loadResources(node.entities, resources, renderer)
  renderer.renderSystem(node.entities, camera)

proc entityModelView(model: EntityModel, controller: EntityController): Node {.procvar.} =
  nodes(@[
    Button(
      pos: vec(1100, 100),
      size: vec(80, 50),
      label: "Exit",
      hotkey: escape,
      onClick: (proc() =
        controller.bufferClose = true
      ),
    ),
    EntityRenderNode(entities: model.entities),
  ])

proc newEntityMenu*(): Menu[EntityModel, EntityController] =
  Menu[EntityModel, EntityController](
    model: newEntityModel(),
    view: entityModelView,
    update: entityModelUpdate,
    controller: EntityController(),
  )
