import
  hashes,
  math,
  sets,
  sdl2,
  sdl2.ttf,
  tables

import
  drawing,
  input,
  program,
  rect,
  resources,
  util,
  vec

const fontName = "nevis.ttf"
var textCache = initTable[string, RenderedText]()

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

proc drawArrow(renderer: RendererPtr, p1, p2: Vec, headSize, radius: float) =
  let
    delta = p2 - p1
    dist = delta.length
    dir = delta.unit
    r = min(dist, radius / 2)
    a = p1 + dir * r
    b = p2 - dir * r
    s = min(dist, headSize)
    headAngle = 0.8 * PI
    c = b + dir.rotate(headAngle) * s
    d = b + dir.rotate(-headAngle) * s
  renderer.drawLine(a, b)
  renderer.drawLine(b, c)
  renderer.drawLine(b, d)

proc draw(renderer: RendererPtr, nodes: seq[ref GraphNode], font: FontPtr) =
  const nodeSize = vec(50)

  renderer.setDrawColor(64, 64, 64)
  for n in nodes:
    for c in n.neighbors:
      renderer.drawArrow(n.pos, c.pos, 20, nodeSize.length)

  for n in nodes:
    renderer.setDrawColor(232, 232, 232)
    renderer.fillRect rect(n.pos, nodeSize)
    renderer.setDrawColor(64, 64, 64)
    renderer.drawRect rect(n.pos, nodeSize)

    let text = $n.id
    if not textCache.hasKey(text):
      textCache[text] = renderer.renderText(text, font, color(64, 64, 64, 255))
    renderer.draw(textCache[text], n.pos)

type MapGen* = ref object of Program
  nodes: seq[ref GraphNode]
  resources: ResourceManager

proc newMapGen(): MapGen =
  new result
  result.resources = newResourceManager()
  result.initProgram()

proc genMap(map: MapGen) =
  let numNodes = random(6, 12)
  var nodes: seq[ref GraphNode] = @[]

  for i in 0..<numNodes:
    let n = newGraphNode()
    n.pos = vec(random(100, 1100), random(100, 800))
    if i > 0:
      nodes[random(0, i-1)].neighbors.add n
    nodes.add n

  map.nodes = nodes

method init(map: MapGen) =
  map.genMap()

method draw*(renderer: RendererPtr, map: MapGen) =
  let font = map.resources.loadFont fontName

  renderer.draw map.nodes, font

method update*(map: MapGen, dt: float) =
  if map.input.isPressed(Input.spell1):
    nextId = 1
    map.genMap()

when isMainModule:
  let
    screenSize = vec(1200, 900)
    map = newMapGen()
  main(map, screenSize)
