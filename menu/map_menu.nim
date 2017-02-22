from sdl2 import RendererPtr

import
  component/[
    transform,
  ],
  nano_mapgen/[
    map,
    room,
  ],
  color,
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

defineComponent(MapContainer)
defineComponent(MapMenu)

proc mapMenuNode(container: MapContainer, player: Entity): Node =
  const
    roomSize = 32.0
    border = 4.0
    screenSize = vec(1200, 900) #TODO: ok stop hardcoding this
    borderColor = rgb(0, 0, 0)
    roomColor = rgb(64, 192, 255)
    doorOffset = roomSize / 2 - vec(border) / 4
    doorWidth = 16.0
  result = Node(
    pos: vec(1050, 825),
    children: @[],
  )
  template addDoor(n: Node, r: Room, dir: untyped, p, s: Vec) =
    if r.dir == doorOpen:
      n.children.add SpriteNode(
        pos: p,
        size: s,
        color: roomColor,
      )
  for room in container.map.rooms:
    let pos = roomSize * vec(room.x, -room.y)
    var node = SpriteNode(
      pos: pos,
      size: vec(roomSize),
      color: borderColor,
      children: @[SpriteNode(
        size: vec(roomSize - border),
        color: roomColor,
      ).Node],
    )
    addDoor(node, room, up,
            vec(0.0, -doorOffset.y),
            vec(doorWidth, border / 2))
    addDoor(node, room, down,
            vec(0.0, doorOffset.y),
            vec(doorWidth, border / 2))
    addDoor(node, room, left,
            vec(-doorOffset.x, 0.0),
            vec(border / 2, doorWidth))
    addDoor(node, room, right,
            vec(doorOffset.x, 0.0),
            vec(border / 2, doorWidth))
    result.children.add node
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
        color: rgb(255, 255, 64),
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
