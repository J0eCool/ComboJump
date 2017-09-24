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
    room*: TileRoom
    data*: seq[seq[bool]]
    tileSize*: Vec
  RoomViewer* = ref object of RoomViewerObj

defineComponent(RoomViewer)

defineDrawSystem:
  components = [RoomViewer, Transform]
  proc drawRoomViewers*(resources: ResourceManager, camera: Camera) =
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

  newEntity("TileRoom", [
    Transform(pos: pos),
    Collider(layer: Layer.floor),
    RoomViewer(
      room: room,
      data: data,
      tileSize: tileSize,
    ),
  ])
