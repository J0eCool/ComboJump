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
    sprite,
    transform,
  ],
  menu/[
    map_menu,
  ],
  color,
  areas,
  entity,
  jsonparse,
  prefabs,
  room_builder,
  stages,
  vec,
  util

const
  wallWidth = 20.0
  doorWidth = 400.0

proc wall(door = doorWall, pos = vec(), size = vec()): Entities =
  const
    wallColor = rgb(128, 128, 128)
    doorColor = rgb(160, 128, 32)
    wallName = "Wall"
  if door == doorWall:
    return @[newEntity(wallName, [
      Sprite(color: wallColor),
      Collider(layer: Layer.floor),
      Transform(pos: pos, size: size)
    ])]

  let
    isVertical = size.y > size.x
    doorSize =
      if isVertical:
        vec(wallWidth, doorWidth)
      else:
        vec(doorWidth, wallWidth)
    doorOffset =
      if isVertical:
        vec(0.0, size.y - doorWidth) / 2
      else:
        vec(0)
  if isVertical:
    let
      partPos = pos - vec(0.0, doorWidth / 2)
      partSize = vec(size.x, size.y - doorWidth)
    result = @[
      newEntity(wallName, [
        Sprite(color: wallColor),
        Collider(layer: Layer.floor),
        Transform(pos: partPos, size: partSize)
      ]),
    ]
  else:
    let
      offset = vec(size.x / 4 + doorWidth / 4, 0.0)
      leftPos = pos - offset
      rightPos = pos + offset
      partSize = vec((size.x - doorWidth) / 2, size.y)
    result = @[
      newEntity(wallName, [
        Sprite(color: wallColor),
        Collider(layer: Layer.floor),
        Transform(pos: leftPos, size: partSize)
      ]),
      newEntity(wallName, [
        Sprite(color: wallColor),
        Collider(layer: Layer.floor),
        Transform(pos: rightPos, size: partSize)
      ]),
    ]
  case door
  of doorWall, doorOpen:
    discard
  of doorLocked:
    result.add newEntity("Door", [
      Sprite(color: doorColor),
      Collider(layer: Layer.floor),
      Transform(
        pos: pos + doorOffset,
        size: doorSize,
      ),
      LockedDoor(),
    ])
  of doorEntrance, doorExit:
    result.add newEntity("Exit", [
      ExitZone(stageEnd: door == doorExit),
      Collider(layer: playerTrigger),
      Transform(
        pos: pos + doorOffset,
        size: doorSize,
      ),
      Sprite(color: rgb(0, 0, 0)),
    ])


proc entities(room: Room, screenSize, pos: Vec): Entities =
  var grid: RoomGrid
  grid.fromJSON(readJSONFile("saved_room.json"))
  grid.seed = random(int.high)
  result = @[
    newEntity("Room", [
      RoomCameraTarget(),
      Collider(layer: Layer.playerTrigger),
      Transform(
        pos: pos + screenSize / 2,
        size: screenSize - vec(2 * wallWidth),
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
    # if room.kind == roomNormal:
    #   const spawnBuffer = vec(100.0)
    #   for enemyKind in stage.randomEnemyKinds:
    #     let pos = random(spawnBuffer, screenSize - spawnBuffer)
    #     result.add newEnemy(enemyKind, stage.level, pos + roomPos)
