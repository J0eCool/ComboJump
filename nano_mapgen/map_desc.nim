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
    kind: RoomKind
    edges: seq[Edge]
  MapGraph = object
    nodes: seq[MapNode]
  MapDesc* = object
    length*: int

proc edgeFor(node, neighbor: MapNode): Edge =
  for edge in node.edges:
    if edge.node == neighbor:
      return edge
  return nil

proc connect(a, b: MapNode) =
  if a.edgeFor(b) == nil:
    a.edges.safeAdd Edge(door: doorOpen, node: b)
  if b.edgeFor(a) == nil:
    b.edges.safeAdd Edge(door: doorOpen, node: a)

proc split(a, b: MapNode): MapNode =
  let
    e1 = a.edgeFor(b)
    e2 = b.edgeFor(a)
  if e1 == nil or e2 == nil:
    return nil

  result = MapNode()
  a.edges.remove(e1)
  b.edges.remove(e2)
  connect(a, result)
  connect(b, result)

proc generateNodes(desc: MapDesc): MapGraph =
  let
    startNode = MapNode(kind: roomStart)
    endNode = MapNode(kind: roomEnd)
  connect(startNode, endNode)
  var nodes = @[startNode, endNode]
  for i in 0..<desc.length - 2:
    nodes.add split(startNode, startNode.edges[0].node)
  MapGraph(nodes: nodes)

proc start(graph: MapGraph): MapNode =
  for node in graph.nodes:
    if node.kind == roomStart:
      return node

proc generate*(desc: MapDesc): Map =
  var
    curNode = desc.generateNodes().start()
    rooms = newSeq[Room]()
    visited = newSeq[MapNode]()
  while curNode != nil:
    let
      id = rooms.len + 1
      next = Room(
        id: id,
        kind: curNode.kind,
        x: 0,
        y: id - 1,
        up: doorOpen,
        down: doorOpen,
      )
    rooms.add next
    visited.add curNode
    var nextNode: MapNode = nil
    for e in curNode.edges:
      if not (e.node in visited):
        nextNode = e.node
        break
    curNode = nextNode
  Map(rooms: rooms)
