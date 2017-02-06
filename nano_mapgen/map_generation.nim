import
  math,
  sdl2

import
  nano_mapgen/[
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
  areas,
  entity,
  prefabs,
  stages,
  vec,
  util

type

const
  wallWidth = 20.0
  doorWidth = 400.0

proc wall(pos = vec(), size = vec(), door = doorWall): Entities =
  let
    wallColor = color(128, 128, 128, 255)
    name = "Wall"
  if door == doorWall:
    return @[newEntity(name, [
      Sprite(color: wallColor),
      Collider(layer: Layer.floor),
      Transform(pos: pos, size: size)
    ])]

  let
    # isVertical = size.x < size.y
    offset = vec(size.x / 4 + doorWidth / 4, 0.0)
    leftPos = pos - offset
    rightPos = pos + offset
    partSize = vec((size.x - doorWidth) / 2, size.y)
  @[
    newEntity(name, [
      Sprite(color: wallColor),
      Collider(layer: Layer.floor),
      Transform(pos: leftPos, size: partSize)
    ]),
    newEntity(name, [
      Sprite(color: wallColor),
      Collider(layer: Layer.floor),
      Transform(pos: rightPos, size: partSize)
    ]),
  ]


proc roomEntities(screenSize, pos: Vec): Entities =
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
  result &= wall( # left
    pos = pos + vec(wallWidth / 2, screenSize.y / 2),
    size = vec(wallWidth, screenSize.y - 2 * wallWidth),
    door = doorWall,
  )
  result &= wall( # right
    pos = pos + vec(screenSize.x - wallWidth / 2, screenSize.y / 2),
    size = vec(wallWidth, screenSize.y - 2 * wallWidth),
    door = doorWall,
  )
  result &= wall( # top
    pos = pos + vec(screenSize.x / 2, wallWidth / 2),
    size = vec(screenSize.x, wallWidth),
    door = doorOpen,
  )
  result &= wall( # bottom
    pos = pos + vec(screenSize.x / 2, screenSize.y - wallWidth / 2),
    size = vec(screenSize.x, wallWidth),
    door = doorOpen,
  )

proc entitiesForStage*(area: AreaInfo, stageIdx: int, player: Entity): Entities =
  let
    stage = area.stageDesc(stageIdx)
    player = if player != nil: player else: newPlayer(vec())
    playerTransform = player.getComponent(Transform)
    screenSize = vec(1200, 900) # TODO: don't hardcode this
    exitSize = vec(doorWidth, wallWidth)
  playerTransform.pos = vec(screenSize.x / 2, screenSize.y * 2 / 3)
  result = @[
    player,
    newHud(),
    newEntity("BeginExit", [
      ExitZone(stageEnd: false),
      Collider(layer: playerTrigger),
      Transform(pos: vec(screenSize.x / 2.0, screenSize.y), size: exitSize),
      Sprite(color: color(0, 0, 0, 255)),
    ]),
    newEntity("EndExit", [
      ExitZone(stageEnd: true),
      Collider(layer: playerTrigger),
      Transform(pos: vec(screenSize.x / 2.0, -(stage.rooms - 1).float * screenSize.y), size: exitSize),
      Sprite(color: color(0, 0, 0, 255)),
    ]),
  ]
  for i in 0..<stage.rooms:
    let roomPos = vec(0.0, -screenSize.y * i.float)
    result &= roomEntities(screenSize, roomPos)
    if i != 0 and i != stage.rooms - 1:
      const spawnBuffer = vec(100.0)
      for enemyKind in stage.randomEnemyKinds:
        let pos = random(spawnBuffer, screenSize - spawnBuffer)
        result.add newEnemy(enemyKind, stage.level, pos + roomPos)
