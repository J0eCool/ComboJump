import
  math,
  random

import
  nano_mapgen/[
    map,
    map_desc,
    room,
  ],
  component/[
    collider,
    exit_zone,
    locked_door,
    room_camera_target,
    room_viewer,
    sprite,
    transform,
  ],
  mapgen/[
    tile_room,
  ],
  menu/[
    map_menu,
  ],
  color,
  areas,
  entity,
  jsonparse,
  prefabs,
  stages,
  vec,
  util

proc entities(room: Room, screenSize, pos: Vec): Entities =
  var grid: RoomGrid
  grid.fromJson(readJsonFile("saved_room.json"))
  grid.seed = random(int.high)
  result = @[
    newEntity("Room", [
      RoomCameraTarget(),
      Collider(layer: Layer.playerTrigger),
      Transform(
        pos: pos + screenSize / 2,
        size: screenSize - vec(50),
      ),
    ]),
    grid.buildRoomEntity(pos, vec(64)),
  ]

proc entitiesForStage*(area: AreaInfo, stageIdx: int, player: Entity): Entities =
  let
    stage = area.stageDesc(stageIdx)
    player = if player != nil: player else: newPlayer(vec())
    playerTransform = player.getComponent(Transform)
    screenSize = vec(1200, 900) # TODO: don't hardcode this
    desc = MapDesc(
      length: stage.rooms,
      numSidePaths: stage.sidePaths,
    )
    map = desc.generate()
  playerTransform.pos = vec(screenSize.x / 2, screenSize.y * 2 / 3)
  result = @[
    player,
    newHud(),
    newEntity("MapContainer", [MapContainer(map: map).Component]),
    newEntity("MapMenu", [MapMenu().Component]),
  ]
  for room in map.rooms:
    let roomPos = screenSize * vec(room.x, -room.y)
    result &= room.entities(screenSize, roomPos)
