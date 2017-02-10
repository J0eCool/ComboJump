import
  sdl2

import
  nano_mapgen/[
    map,
    room,
  ],
  input,
  entity,
  event,
  game_system,
  menu,
  resources,
  vec,
  util

type
  MapContainer* = ref object of Component
    map*: Map
  MapMenu* = ref object of Component
    menu: Node

proc mapMenuNode(container: MapContainer): Node =
  result = Node(
    pos: vec(1000, 400),
    children: @[],
  )
  const
    roomSize = 32.0
    border = 4.0
  for room in container.map.rooms:
    let pos = roomSize * vec(room.x, -room.y)
    result.children.add SpriteNode(
      pos: pos,
      size: vec(roomSize),
      color: color(0, 0, 0, 255),
      children: @[SpriteNode(
        size: vec(roomSize - border),
        color: color(64, 192, 255, 255),
      ).Node],
    )

defineDrawSystem:
  priority = -100
  proc drawMapMenu*(resources: var ResourceManager) =
    entities.forComponents entity, [
      MapMenu, mapMenu,
    ]:
      renderer.draw(mapMenu.menu, resources)

defineSystem:
  components = [MapMenu]
  proc updateMapMenu*(input: InputManager) =
    if mapMenu.menu == nil:
      entities.forComponents e2, [
        MapContainer, mapContainer,
      ]:
        mapMenu.menu = mapMenuNode(mapContainer)
        break
    mapMenu.menu.update(input)
