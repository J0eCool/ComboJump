import random
from sdl2 import RendererPtr

import
  component/[
    collider,
    sprite,
    transform,
  ],
  mapgen/[
    room_drawing,
    tile_room,
  ],
  camera,
  drawing,
  entity,
  event,
  game_system,
  rect,
  resources,
  vec

type
  RoomViewerObj* = object of ComponentObj
    room: TileRoom
    tileSize: Vec
  RoomViewer* = ref object of RoomViewerObj

defineComponent(RoomViewer)

defineDrawSystem:
  components = [RoomViewer, Transform]
  proc drawRoomViewers*(resources: var ResourceManager, camera: Camera) =
    renderer.drawRoom(
      resources,
      roomViewer.room,
      transform.globalPos + camera.offset,
      roomViewer.tileSize)

proc buildRoomEntity*(grid: RoomGrid, pos, tileSize: Vec): Entity =
  randomize(grid.seed)
  let
    data = grid.data.selectRandomTiles()
    room = grid.buildRoom(data)

  var colliders = newSeq[Entity]()
  for x in 0..<grid.w:
    for y in 0..<grid.h:
      if data[x][y]:
        colliders.add newEntity("Collider", [
          Transform(
            pos: tileSize * vec(x, y),
            size: tileSize,
          ),
          Collider(layer: floor),
        ])

  newEntity("TileRoom", [
    Transform(pos: pos),
    RoomViewer(
      room: room,
      tileSize: tileSize,
    ),
  ],
  children=colliders)
