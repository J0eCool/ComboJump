import tables

import
  nano_mapgen/room,
  logging,
  option,
  util

type Map* = object
  rooms*: seq[Room]

proc startRoom*(map: Map): Option[Room] =
  for room in map.rooms:
    if room.kind == roomStart:
      return makeJust(room)
  makeNone[Room]()

proc endRoom*(map: Map): Option[Room] =
  for room in map.rooms:
    if room.kind == roomEnd:
      return makeJust(room)
  makeNone[Room]()

proc getRoom*(map: Map, id: int): Option[Room] =
  for room in map.rooms:
    if room.id == id:
      return makeJust(room)
  makeNone[Room]()

proc getRoomAt*(map: Map, x, y: int): Option[Room] =
  for room in map.rooms:
    if room.x == x and room.y == y:
      return makeJust(room)
  makeNone[Room]()

proc findPath*(map: Map, a, b: Room): seq[Room] =
  var
    openSet = @[a.id]
    visited = initTable[int, int]()
  visited[a.id] = 0

  template tryAdd(cur: Room, field: untyped, dx, dy: int): untyped =
    if cur.field != doorWall:
      let nextOpt = map.getRoomAt(cur.x + dx, cur.y + dy)
      nextOpt.bindAs next:
        if not visited.hasKey(next.id):
          openSet.add(next.id)
          visited[next.id] = cur.id
          if next.id == b.id:
            break

  while openSet.len > 0:
    let curOpt = map.getRoom(openSet[0])
    openSet.delete(0)
    assert curOpt.kind != none, "Invalid room ID in openSet"
    let cur = curOpt.value
    tryAdd(cur, up, 0, 1)
    tryAdd(cur, down, 0, -1)
    tryAdd(cur, left, -1, 0)
    tryAdd(cur, right, 1, 0)

  if not visited.hasKey(b.id):
    return @[]

  result = @[b]
  while result[0] != a:
    let cur = result[0]
    assert(visited.hasKey(cur.id),
      "Backtracing path finds parent that wasn't visited")
    let
      prevId = visited[cur.id]
      prevOpt = map.getRoom(prevId)
    assert prevOpt.kind != none, "Room has invalid parent"
    let prev = prevOpt.value
    assert(not (prev in result), "Cycle found when backtracing path")
    result.insert(prev, 0)

proc textMap*(map: Map): string =
  let firstRoom = map.rooms[0]
  var
    minX = firstRoom.x
    maxX = firstRoom.x
    minY = firstRoom.y
    maxY = firstRoom.y
  for room in map.rooms:
    minX.min = room.x
    maxX.max = room.x
    minY.min = room.y
    maxY.max = room.y
  result = "END - X = [" & $minX & ", " & $maxX & "] : Y = [" & $minY & ", " & $maxY & "]"
  for y in minY..maxY:
    var line = ""
    for x in minX..maxX:
      let roomOpt = map.getRoomAt(x, y)
      if roomOpt.kind == none:
        line &= "."
        continue
      let room = roomOpt.value
      if room.up == doorLocked:
        line &= "L"
        continue
      case room.kind
      of roomNormal:
        line &= "O"
      of roomStart:
        line &= "S"
      of roomEnd:
        line &= "E"
      of roomKey:
        line &= "K"
    result = line & "\n" & result
  result = "BEGIN\n" & result
