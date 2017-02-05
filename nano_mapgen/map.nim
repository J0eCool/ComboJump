import tables

import
  logging,
  option

type
  Direction* = enum
    dirLeft
    dirRight
    dirUp
    dirDown
  RoomKind* = enum
    roomNormal
    roomStart
    roomEnd
  Room* = object
    id*: int
    left*: int
    right*: int
    up*: int
    down*: int
    kind*: RoomKind
  Map* = object
    rooms*: seq[Room]
  MapSolution* = object
    path: seq[Room]

proc startRoom(map: Map): Option[Room] =
  for room in map.rooms:
    if room.kind == roomStart:
      return makeJust(room)
  makeNone[Room]()

proc endRoom(map: Map): Option[Room] =
  for room in map.rooms:
    if room.kind == roomEnd:
      return makeJust(room)
  makeNone[Room]()

proc getRoom(map: Map, id: int): Option[Room] =
  for room in map.rooms:
    if room.id == id:
      return makeJust(room)
  makeNone[Room]()

proc findPath(map: Map, a, b: Room): seq[Room] =
  var
    openSet = @[a.id]
    visited = initTable[int, int]()
  visited[a.id] = 0

  template tryAdd(room: Room, field: untyped): untyped =
    if room.field != 0 and (not visited.hasKey(room.field)):
      openSet.add(room.field)
      visited[room.field] = room.id
      if room.field == b.id:
        break

  while openSet.len > 0:
    let curOpt = map.getRoom(openSet[0])
    if curOpt.kind == none:
      log("MapGen", error, "Invalid room ID found! ",
        "Ignoring for now. id = ", openSet[0])
      continue
    openSet.delete(0)
    let cur = curOpt.value
    tryAdd(cur, up)
    tryAdd(cur, down)
    tryAdd(cur, left)
    tryAdd(cur, right)

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

proc solve*(map: Map): MapSolution =
  let
    startOpt = map.startRoom()
    endOpt = map.endRoom()
  if startOpt.kind == none or endOpt.kind == none:
    return MapSolution()

  let
    startRoom = startOpt.value
    endRoom = endOpt.value
    path = map.findPath(startRoom, endRoom)
  MapSolution(path: path)

proc length*(solution: MapSolution): int =
  if solution.path == nil:
    return 0
  solution.path.len

proc pathExists*(solution: MapSolution): bool =
  solution.length > 0
