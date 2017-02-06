import
  nano_mapgen/[
    map,
    room,
  ],
  util

type
  MapDesc* = object
    length*: int

proc generate*(desc: MapDesc): Map =
  var
    startRoom = Room(
      id: 1,
      kind: roomStart,
      x: 0,
      y: 0,
      up: doorOpen,
      down: doorOpen,
    )
    rooms = @[startRoom]
    nextId = 2
    nextY = 1
  while nextY < desc.length:
    let
      next = Room(
        id: nextId,
        x: 0,
        y: nextY,
        up: doorOpen,
        down: doorOpen,
      )
    rooms.add next
    if randomBool(0.3):
      var alt = Room(
        id: nextId,
        y: nextY,
      )
      if randomBool():
        alt.x = 1
        alt.left = doorOpen
        rooms[rooms.len - 1].right = doorOpen
      else:
        alt.x = -1
        alt.right = doorOpen
        rooms[rooms.len - 1].left = doorOpen
      rooms.add alt
      nextId += 1
    nextId += 1
    nextY += 1
  rooms[rooms.len - 1].kind = roomEnd
  Map(rooms: rooms)
