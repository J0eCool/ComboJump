import
  sdl2

import
  component/[
    transform,
  ],
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

proc mapMenuNode(container: MapContainer, player: Entity): Node =
  const
    roomSize = 32.0
    border = 4.0
    screenSize = vec(1200, 900) #TODO: ok stop hardcoding this
  result = Node(
    pos: vec(1000, 400),
    children: @[],
  )
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
  let
    playerTransform = player.getComponent(Transform)
    getPlayerPos = proc(): Vec =
      playerTransform.pos
  result.children.add BindNode[Vec](
    item: getPlayerPos,
    node: (proc(pos: Vec): Node =
      SpriteNode(
        pos: (pos / screenSize - vec(0.5)) * vec(roomSize),
        size: vec(12),
        color: color(255, 255, 64, 255),
      )
    ),
  )

defineDrawSystem:
  priority = -100
  components = [MapMenu]
  proc drawMapMenu*(resources: var ResourceManager) =
    if mapMenu.menu != nil:
      renderer.draw(mapMenu.menu, resources)

defineSystem:
  components = [MapMenu]
  proc updateMapMenu*(input: InputManager, player: Entity) =
    if mapMenu.menu == nil and player != nil:
      entities.forComponents e2, [
        MapContainer, mapContainer,
      ]:
        mapMenu.menu = mapMenuNode(mapContainer, player)
        break

    if mapMenu.menu != nil:
      mapMenu.menu.update(input)
