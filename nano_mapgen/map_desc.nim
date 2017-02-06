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
    startRoom = Room(id: 1, kind: roomStart)
    rooms = @[startRoom]
    nextId = 2
  while rooms.len < desc.length:
    let
      lastIdx = rooms.len - 1
      next = Room(id: nextId, down: rooms[lastIdx].id)
    rooms[lastIdx].up = nextId
    rooms.add next
    nextId += 1
  rooms[rooms.len - 1].kind = roomEnd
  Map(rooms: rooms)
