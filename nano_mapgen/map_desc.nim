import
  hashes,
  sequtils,
  tables

import
  nano_mapgen/[
    map,
    room,
  ],
  util

type
  Edge = ref object
    door: DoorKind
    node: MapNode
  MapNode = ref object
    id: int
    kind: RoomKind
    edges: seq[Edge]
    length: int
  MapGraph = object
    nodes: seq[MapNode]
    startNode: MapNode
    endNode: MapNode
  MapDesc* = object
    length*: int

proc `$`(node: MapNode): string =
  "n" & $node.id

proc `$`(edge: Edge): string =
  "(" & $edge.door & " -> " & $edge.node & ")"

proc `$`(graph: MapGraph): string =
  result = "Graph with " & $graph.nodes.len & " nodes:\n"
  for node in graph.nodes:
    result &= (
      "  " & $node &
      ": len " & $node.length &
      ", " & $node.kind &
      " - " & $node.edges &
      "\n"
    )

var nextMapId = 0
proc newMapNode(kind = roomNormal, length = 1): MapNode =
  result = MapNode(
    id: nextMapId,
    kind: kind,
    edges: @[],
    length: length,
  )
  nextMapId += 1

proc hash(node: MapNode): Hash =
  node.id.hash

proc edgeFor(node, neighbor: MapNode): Edge =
  for edge in node.edges:
    if edge.node == neighbor:
      return edge
  return nil

proc connect(a, b: MapNode, door = doorOpen) =
  if a.edgeFor(b) == nil:
    a.edges.add Edge(door: door, node: b)
  if b.edgeFor(a) == nil:
    b.edges.add Edge(door: door, node: a)

proc split(a, b: MapNode): MapNode =
  let
    e1 = a.edgeFor(b)
    e2 = b.edgeFor(a)
  if e1 == nil or e2 == nil:
    return nil

  result = newMapNode()
  a.edges.remove(e1)
  b.edges.remove(e2)
  connect(a, result, e1.door)
  connect(b, result, e2.door)

proc findPath(a, b: MapNode): seq[MapNode] =
  var
    openSet = @[a]
    visited = initTable[MapNode, MapNode]()
  visited[a] = nil

  while openSet.len > 0:
    let cur = openSet[0]
    openSet.delete(0)
    for e in cur.edges:
      let next = e.node
      if not visited.hasKey(next):
        openSet.add(next)
        visited[next] = cur
        if next == b:
          break

  if not visited.hasKey(b):
    return @[]

  result = @[b]
  while result[0] != a:
    let cur = result[0]
    assert(visited.hasKey(cur),
      "Backtracing path finds parent that wasn't visited")
    let prev = visited[cur]
    assert(not (prev in result), "Cycle found when backtracing path")
    result.insert(prev, 0)

proc generateNodes(desc: MapDesc): MapGraph =
  let
    startNode = newMapNode(roomStart)
    endNode = newMapNode(roomEnd)
  connect(startNode, endNode)
  var nodes = @[startNode, endNode]
  let mainHall = split(startNode, endNode)
  mainHall.length = desc.length - 2
  nodes.add mainHall
  let numSidePaths = random(0, desc.length div 2)
  for i in 0..<numSidePaths:
    let
      mainPath = findPath(startNode, endNode)
      lockIdx = random(1, mainPath.len - 2)
      sideLen = random(1, 2)
      base = mainPath[lockIdx]
      prev = mainPath[lockIdx - 1]
      newHall = split(prev, base)
      newLen = random(1, max(base.length - 1, 1))
      newEdge = newHall.edgeFor(base)
      keyHall = newMapNode(roomNormal, sideLen - 1)
      keyRoom = newMapNode(roomKey)
    newHall.length = newLen
    base.length = max(base.length - newLen, 1)
    newEdge.door = doorLocked
    nodes.add newHall
    if keyHall.length == 0:
      connect(keyRoom, newHall)
    else:
      connect(keyHall, newHall)
      connect(keyRoom, keyHall)
      nodes.add keyHall
    nodes.add keyRoom
  MapGraph(
    nodes: nodes,
    startNode: startNode,
    endNode: endNode,
  )

proc generateMap*(graph: MapGraph): Map =
  var
    mainPath = findPath(graph.startNode, graph.endNode)
    nextId = 2
    rooms = initTable[MapNode, seq[ref Room]]()
    nodesLeft = graph.nodes
  let startRoom = Room(
    id: 1,
    kind: roomStart,
    x: 0,
    y: 0,
    down: doorEntrance,
  )
  rooms[graph.startNode] = @[newOf(startRoom)]
  nodesLeft.remove(graph.startNode)

  while nodesLeft.len > 0:
    var toRemove = newSeq[MapNode]()
    for node in nodesLeft:
      for edge in node.edges:
        let parent = edge.node
        if not rooms.hasKey(parent):
          continue
        let
          parentRooms = rooms[parent]
          isMainPath = node in mainPath
          openParents =
            if isMainPath:
              @[parentRooms[parentRooms.len - 1]]
            else:
              filter(parentRooms) do (room: ref Room) -> bool:
                room.left == doorWall or room.right == doorWall
          room = random(openParents)
          xDir =
            if isMainPath:
              0
            elif room.left == doorWall and room.right == doorWall:
              if randomBool(): 1 else: -1
            elif room.left == doorWall:
              -1
            else:
              1
          yDir = if isMainPath: 1 else: 0
        var curRooms = newSeq[ref Room]()
        for i in 1..node.length:
          curRooms.add newOf(Room(
            id: nextId,
            kind: node.kind,
            x: room.x + xDir * i,
            y: room.y + yDir * i,
          ))
          nextId += 1
        rooms[node] = curRooms
        template openDoors(prev, cur: untyped) =
          room.prev = parent.edgeFor(node).door
          for i in 0..<curRooms.len:
            let r = curRooms[i]
            r.cur = doorOpen
            if i != curRooms.len - 1:
              r.prev = doorOpen
        if yDir == 1:
          openDoors(up, down)
        elif xDir == 1:
          openDoors(right, left)
        else:
          openDoors(left, right)
        toRemove.add node
        break
    for node in toRemove:
      nodesLeft.remove node
  rooms[graph.endNode][0].up = doorExit

  result = Map(rooms: @[])
  for node in graph.nodes:
    if rooms.hasKey node:
      for room in rooms[node]:
        result.rooms.add room[]

proc generate*(desc: MapDesc): Map =
  let graph = desc.generateNodes()
  graph.generateMap()

when isMainModule:
  import random
  randomize()
  for i in 1..10:
    echo "Map - ", i
    let graph = MapDesc(length: 9).generateNodes
    echo graph
    echo graph.generateMap.textMap
    echo ""
