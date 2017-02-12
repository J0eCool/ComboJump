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
    rooms = newSeq[Room]()
    path = findPath(graph.startNode, graph.endNode)
  for i in 0..<path.len:
    let
      node = path[i]
      id = rooms.len + 1
      next = Room(
        id: id,
        kind: node.kind,
        x: 0,
        y: id - 1,
        up: doorOpen,
        down: doorOpen,
      )
    rooms.add next
  Map(rooms: rooms)
