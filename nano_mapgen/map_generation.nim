import
  math,
  sdl2

import
  nano_mapgen/[
    map,
    map_desc,
    room,
  ],
  component/[
    collider,
    exit_zone,
    room_camera_target,
    sprite,
    target_shooter,
    transform,
  ],
  menu/[
    map_menu,
  ],
  areas,
  entity,
  prefabs,
  stages,
  vec,
  util

const
  wallWidth = 20.0
  doorWidth = 400.0

proc wall(door = doorWall, pos = vec(), size = vec()): Entities =
  const
    wallColor = color(128, 128, 128, 255)
    doorColor = color(160, 128, 32, 255)
    exitSize = vec(doorWidth, wallWidth)
    wallName = "Wall"
  if door == doorWall:
    return @[newEntity(wallName, [
      Sprite(color: wallColor),
      Collider(layer: Layer.floor),
      Transform(pos: pos, size: size)
    ])]

  let
    isVertical = size.y > size.x
    offset =
      if isVertical:
        vec(0.0, size.y / 4 + doorWidth / 4)
      else:
        vec(size.x / 4 + doorWidth / 4, 0.0)
    leftPos = pos - offset
    rightPos = pos + offset
    partSize =
      if isVertical:
        vec(size.x, (size.y - doorWidth) / 2)
      else:
        vec((size.x - doorWidth) / 2, size.y)
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
        pos: pos + vec(doorWidth / 4, 0.0),
        size: vec(doorWidth / 2, wallWidth),
      ),
    ])
  of doorEntrance, doorExit:
    result.add newEntity("Exit", [
      ExitZone(stageEnd: door == doorExit),
      Collider(layer: playerTrigger),
      Transform(
        pos: pos,
        size: exitSize,
      ),
      Sprite(color: color(0, 0, 0, 255)),
    ])


proc entities(room: Room, screenSize, pos: Vec): Entities =
  result = @[
    newEntity("Room", [
      RoomCameraTarget(),
      Collider(layer: Layer.playerTrigger),
      Transform(
        pos: pos + screenSize / 2,
        size: screenSize - vec(2 * wallWidth),
      ),
    ]),
  ]
  result &= wall(
    door = room.left,
    pos = pos + vec(wallWidth / 2, screenSize.y / 2),
    size = vec(wallWidth, screenSize.y - 2 * wallWidth),
  )
  result &= wall( # right
    door = room.right,
    pos = pos + vec(screenSize.x - wallWidth / 2, screenSize.y / 2),
    size = vec(wallWidth, screenSize.y - 2 * wallWidth),
  )
  result &= wall( # top
    door = room.up,
    pos = pos + vec(screenSize.x / 2, wallWidth / 2),
    size = vec(screenSize.x, wallWidth),
  )
  result &= wall( # bottom
    door = room.down,
    pos = pos + vec(screenSize.x / 2, screenSize.y - wallWidth / 2),
    size = vec(screenSize.x, wallWidth),
  )
  if room.kind == roomKey:
    result.add newEntity("Key", [
      Transform(pos: pos + screenSize / 2, size: vec(56, 28)),
      Sprite(textureName: "Key.png"),
    ])

proc entitiesForStage*(area: AreaInfo, stageIdx: int, player: Entity): Entities =
  let
    stage = area.stageDesc(stageIdx)
    player = if player != nil: player else: newPlayer(vec())
    playerTransform = player.getComponent(Transform)
    screenSize = vec(1200, 900) # TODO: don't hardcode this
    desc = MapDesc(length: stage.rooms)
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
    if room.kind == roomNormal:
      const spawnBuffer = vec(100.0)
      for enemyKind in stage.randomEnemyKinds:
        let pos = random(spawnBuffer, screenSize - spawnBuffer)
        result.add newEnemy(enemyKind, stage.level, pos + roomPos)
