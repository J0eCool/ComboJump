import hashes, tables

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
  MapGraph = object
    nodes: seq[MapNode]
    startNode: MapNode
    endNode: MapNode
  MapDesc* = object
    length*: int

proc `$`(node: MapNode): string =
  "n" & $node.id

var nextMapId = 0
proc newMapNode(kind = roomNormal): MapNode =
  result = MapNode(
    id: nextMapId,
    kind: kind,
    edges: @[],
  )
  nextMapId += 1

proc hash(node: MapNode): Hash =
  node.id.hash

proc edgeFor(node, neighbor: MapNode): Edge =
  for edge in node.edges:
    if edge.node == neighbor:
      return edge
  return nil

proc connect(a, b: MapNode) =
  if a.edgeFor(b) == nil:
    a.edges.add Edge(door: doorOpen, node: b)
  if b.edgeFor(a) == nil:
    b.edges.add Edge(door: doorOpen, node: a)

proc split(a, b: MapNode): MapNode =
  let
    e1 = a.edgeFor(b)
    e2 = b.edgeFor(a)
  if e1 == nil or e2 == nil:
    return nil

  result = newMapNode()
  a.edges.remove(e1)
  b.edges.remove(e2)
  connect(a, result)
  connect(b, result)

proc generateNodes(desc: MapDesc): MapGraph =
  let
    startNode = newMapNode(roomStart)
    endNode = newMapNode(roomEnd)
  connect(startNode, endNode)
  var nodes = @[startNode, endNode]
  for i in 0..<desc.length - 2:
    nodes.add split(startNode, startNode.edges[0].node)
  let
    mainPath = nodes
    numSidePaths = random(0, desc.length div 2)
  var openMainPath = mainPath
  for i in 0..<numSidePaths:
    let
      sideLen = random(1, 4)
      base = random(openMainPath)
    var cur = base
    for j in 0..<sideLen:
      let next = newMapNode()
      connect(next, cur)
      nodes.add next
      cur = next
    if base.edges.len >= 4 or (base.kind != roomNormal and base.edges.len >= 3):
      openMainPath.remove base
      if openMainPath.len == 0:
        break
  MapGraph(
    nodes: nodes,
    startNode: startNode,
    endNode: endNode,
  )

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

proc generate*(desc: MapDesc): Map =
  var
    graph = desc.generateNodes()
    mainPath = findPath(graph.startNode, graph.endNode)
    nextId = 1
    rooms = initTable[MapNode, Room]()
    nodesLeft = graph.nodes
  for i in 0..<mainPath.len:
    let
      node = mainPath[i]
      next = Room(
        id: nextId,
        kind: node.kind,
        x: 0,
        y: nextId-1,
        up: doorOpen,
        down: doorOpen,
      )
    rooms[node] = next
    nodesLeft.remove(node)
    nextId += 1

  while nodesLeft.len > 0:
    var toRemove = newSeq[MapNode]()
    for node in nodesLeft:
      for edge in node.edges:
        let parent = edge.node
        if not rooms.hasKey(parent):
          continue
        let
          parentRoom = rooms[parent]
          dir =
            if parentRoom.left == doorWall and parentRoom.right == doorWall:
              if randomBool(): 1 else: -1
            elif parentRoom.left == doorWall:
              -1
            else:
              1
          next = Room(
            id: nextId,
            kind: node.kind,
            x: parentRoom.x + dir,
            y: parentRoom.y,
          )
        rooms[node] = next
        if dir == 1:
          rooms[node].left = doorOpen
          rooms[parent].right = doorOpen
        else:
          rooms[node].right = doorOpen
          rooms[parent].left = doorOpen
        toRemove.add node
        nextId += 1
        break
    for node in toRemove:
      nodesLeft.remove node
    break

  result = Map(rooms: @[])
  for node in graph.nodes:
    if rooms.hasKey node:
      result.rooms.add rooms[node]

when isMainModule:
  import random
  randomize()
  for i in 1..10:
    echo "Map - ", i
    echo MapDesc(length: 9).generate.textMap
    echo ""
