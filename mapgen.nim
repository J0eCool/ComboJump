import
  hashes,
  sets,
  sdl2,
  sdl2.ttf

import
  drawing,
  program,
  rect,
  resources,
  vec

const fontName = "nevis.ttf"

var nextId = 1
type GraphNode = object
  id: int
  pos: Vec
  neighbors: seq[ref GraphNode]

proc newGraphNode(): ref GraphNode =
  new result
  result.id = nextId
  result.neighbors = @[]
  nextId += 1

proc hash(node: ref GraphNode): Hash =
  node.id.Hash

proc firstItem[T](s: HashSet[T]): T =
  assert(s.len > 0)
  for n in s.items:
    return n

proc draw(renderer: RendererPtr, node: ref GraphNode, font: FontPtr) =
  var
    nodesToDraw: seq[ref GraphNode] = @[]
    linesToDraw: seq[tuple[p1: Vec, p2: Vec]] = @[]
    openSet = initSet[ref GraphNode]()
    closedSet = initSet[ref GraphNode]()

  openSet.incl node
  closedSet.incl node

  while openSet.len > 0:
    let n = openSet.firstItem
    openSet.excl n

    nodesToDraw.add n
    for c in n.neighbors:
      linesToDraw.add((n.pos, c.pos))
      if (not closedSet.contains(c)):
        openSet.incl c
        closedSet.incl c

  renderer.setDrawColor(64, 64, 64)
  for line in linesToDraw:
    renderer.drawLine(line.p1, line.p2)

  const size = vec(50)
  for n in nodesToDraw:
    renderer.setDrawColor(232, 232, 232)
    renderer.fillRect rect(n.pos, size)
    renderer.setDrawColor(64, 64, 64)
    renderer.drawRect rect(n.pos, size)

    renderer.drawText($n.id, n.pos, font, color(64, 64, 64, 255))

type MapGen* = ref object of Program
  root: ref GraphNode
  resources: ResourceManager

proc newMapGen(): MapGen =
  new result
  result.resources = newResourceManager()
  result.initProgram()

proc genMap(map: MapGen) =
  let
    n1 = newGraphNode()
    n2 = newGraphNode()
    n3 = newGraphNode()
    n4 = newGraphNode()
  n1.pos = vec(400, 400)
  n2.pos = vec(700, 500)
  n3.pos = vec(800, 200)
  n4.pos = vec(200, 800)

  n1.neighbors = @[n2, n3]
  n2.neighbors = @[n1, n4]
  n4.neighbors = @[n3]

  map.root = n1

method draw*(renderer: RendererPtr, map: MapGen) =
  let font = map.resources.loadFont fontName

  renderer.draw map.root, font

method update*(map: MapGen, dt: float) =
  discard

when isMainModule:
  let
    screenSize = vec(1200, 900)
    map = newMapGen()
  map.genMap()
  main(map, screenSize)
