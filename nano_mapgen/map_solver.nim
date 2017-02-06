import
  nano_mapgen/[
    map,
    room,
  ],
  option

type MapSolution* = object
  path: seq[Room]

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
