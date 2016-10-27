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
  option,
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

proc draw(renderer: RendererPtr, nodes: seq[ref GraphNode], font: FontPtr, camera: Vec) =
  const nodeSize = vec(50)

  renderer.setDrawColor(64, 64, 64)
  for n in nodes:
    for c in n.neighbors:
      renderer.drawArrow(n.pos - camera, c.pos - camera, 20, nodeSize.length)

  for n in nodes:
    let pos = n.pos - camera
    renderer.setDrawColor(232, 232, 232)
    renderer.fillRect rect(pos, nodeSize)
    renderer.setDrawColor(64, 64, 64)
    renderer.drawRect rect(pos, nodeSize)

    let text = $n.id
    if not textCache.hasKey(text):
      textCache[text] = renderer.renderText(text, font, color(64, 64, 64, 255))
    renderer.draw(textCache[text], pos)

type MapGen* = ref object of Program
  nodes: seq[ref GraphNode]
  resources: ResourceManager
  camera: Vec
  lastMousePos: Option[Vec]

proc newMapGen(): MapGen =
  new result
  result.resources = newResourceManager()
  result.initProgram()

proc genMap(map: MapGen, numNodes: int) =
  var nodes: seq[ref GraphNode] = @[]

  for i in 0..<numNodes:
    let n = newGraphNode()
    n.pos = vec(random(100, 1100), random(100, 800))
    if i > 0:
      nodes[random(0, i-1)].neighbors.add n
    nodes.add n

  map.nodes = nodes

proc applyForces(nodes: seq[ref GraphNode], dt: float) =
  var forces = initTable[ref GraphNode, Vec]()
  for n in nodes:
    forces[n] = vec()
  for n in nodes:
    for c in nodes:
      let
        delta = n.pos - c.pos
        dist = max(delta.length2, 10)
      forces[n] += delta.unit() / dist * 1000000

    for c in n.neighbors:
      let
        delta = c.pos - n.pos
        dist = delta.length - 100
        toMove = delta.unit() * dist
      forces[n] += toMove
      forces[c] -= toMove

  for n in nodes:
    n.pos += forces[n] * dt

method init(map: MapGen) =
  map.genMap(12)

method draw*(renderer: RendererPtr, map: MapGen) =
  let font = map.resources.loadFont fontName

  renderer.draw map.nodes, font, map.camera

method update*(map: MapGen, dt: float) =
  if map.input.isPressed(Input.spell1):
    nextId = 1
    map.genMap(random(107,121))

  let mouse = map.input.clickHeldPos()
  map.lastMousePos.bindAs pos:
    mouse.bindAs mousePos:
      map.camera += pos - mousePos
  map.lastMousePos = mouse

  for i in 0..10:
    applyForces(map.nodes, dt*2)

when isMainModule:
  let
    screenSize = vec(1200, 900)
    map = newMapGen()
  main(map, screenSize)
