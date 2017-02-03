import
  math,
  sdl2

import
  component/[
    collider,
    room_camera_target,
    sprite,
    target_shooter,
    transform,
  ],
  entity,
  vec,
  util

proc wall(pos = vec(), size = vec(), hasDoor = false): Entities =
  let
    wallColor = color(128, 128, 128, 255)
    doorWidth = 200.0
    name = "Wall"
  if not hasDoor:
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


proc roomEntities*(screenSize, pos: Vec): Entities =
  let wallWidth = 50.0
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
  )
  result &= wall( # right
    pos = pos + vec(screenSize.x - wallWidth / 2, screenSize.y / 2),
    size = vec(wallWidth, screenSize.y - 2 * wallWidth),
  )
  result &= wall( # top
    pos = pos + vec(screenSize.x / 2, wallWidth / 2),
    size = vec(screenSize.x, wallWidth),
    hasDoor = true,
  )
  result &= wall( # bottom
    pos = pos + vec(screenSize.x / 2, screenSize.y - wallWidth / 2),
    size = vec(screenSize.x, wallWidth),
    hasDoor = true,
  )
