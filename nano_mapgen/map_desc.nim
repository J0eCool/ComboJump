import
  nano_mapgen/[
    map,
    room,
  ]

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
  while rooms.len < desc.length:
    let
      next = Room(
        id: nextId,
        x: 0,
        y: nextY,
        up: doorOpen,
        down: doorOpen,
      )
    rooms.add next
    nextId += 1
    nextY += 1
  rooms[rooms.len - 1].kind = roomEnd
  Map(rooms: rooms)
