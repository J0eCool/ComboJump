from sdl2 import RendererPtr

import
  component/[
    popup_text,
    room_viewer,
  ],
  system/[
    render,
  ],
  camera,
  entity,
  event,
  game_system,
  input,
  menu,
  resources

type
  UpdateProc = proc()
  EntityRenderNode* = ref object of Node
    entities*: Entities
    resources*: ResourceManager
    camera*: Camera
    update*: UpdateProc

method typeName(node: EntityRenderNode): string =
  "EntityRenderNode"

method updateSelf(node: EntityRenderNode, manager: var MenuManager, input: InputManager) =
  node.update()

method diffSelf(node, newVal: EntityRenderNode) =
  node.entities = newVal.entities
  node.camera = newVal.camera

defineSystemCalls(EntityRenderNode)

method drawSelf(node: EntityRenderNode, renderer: RendererPtr, resources: ResourceManager) =
  loadResources(node.entities, resources, renderer)
  node.resources = resources
  renderer.drawSystems(node)
