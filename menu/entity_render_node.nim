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
  menu,
  resources

type EntityRenderNode* = ref object of Node
  entities*: Entities
  resources*: ResourceManager
  camera*: Camera

method typeName(node: EntityRenderNode): string =
  "EntityRenderNode"

method diffSelf(node, newVal: EntityRenderNode) =
  node.entities = newVal.entities
  node.camera = newVal.camera

defineSystemCalls(EntityRenderNode)

method drawSelf(node: EntityRenderNode, renderer: RendererPtr, resources: ResourceManager) =
  loadResources(node.entities, resources, renderer)
  node.resources = resources
  renderer.drawSystems(node)
