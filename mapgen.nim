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

proc draw(renderer: RendererPtr, nodes: seq[ref GraphNode], font: FontPtr, camera: Vec, zoom: float) =
  let
    nodeWidth = 50 * zoom
    nodeSize = vec(nodeWidth)
    arrowSize = 20 * zoom

  renderer.setDrawColor(64, 64, 64)
  for n in nodes:
    let nPos = n.pos * zoom - camera
    for c in n.neighbors:
      let cPos = c.pos * zoom - camera
      renderer.drawArrow(nPos, cPos, arrowSize, nodeWidth)

  for n in nodes:
    let pos = n.pos * zoom - camera
    renderer.setDrawColor(232, 232, 232)
    renderer.fillRect rect(pos, nodeSize)
    renderer.setDrawColor(64, 64, 64)
    renderer.drawRect rect(pos, nodeSize)

    let text = $n.id
    if not textCache.hasKey(text):
      textCache[text] = renderer.renderText(text, font, color(64, 64, 64, 255))
    renderer.draw(textCache[text], pos)

type
  Stage = enum
    spacing,
    splitting,
    legalizing,
    done

  MapGen* = ref object of Program
    nodes: seq[ref GraphNode]
    resources: ResourceManager
    camera: Vec
    lastMousePos: Option[Vec]
    zoomLevel: int
    screenSize: Vec
    stage: Stage
    iterations: int

const
  zoomLevels = 15
  zoomPower = 1.3
  midZoomLevel = zoomLevels div 2

proc newMapGen(screenSize: Vec): MapGen =
  new result
  result.screenSize = screenSize
  result.resources = newResourceManager()
  result.zoomLevel = midZoomLevel
  result.initProgram()

proc zoomScale(map: MapGen): float =
  let lvl = map.zoomLevel - midZoomLevel
  pow(zoomPower, lvl.float)

proc genMap(map: MapGen, numNodes: int) =
  var nodes: seq[ref GraphNode] = @[]

  for i in 0..<numNodes:
    let n = newGraphNode()
    n.pos = vec(random(100, 1100), random(100, 800))
    if i > 0:
      nodes[random(0, i-1)].neighbors.add n
    nodes.add n

  map.nodes = nodes
  map.stage = spacing
  map.iterations = 0

type Edge = tuple[a, b: ref GraphNode]
proc edges(nodes: seq[ref GraphNode]): seq[Edge] =
  result = @[]
  for n in nodes:
    for c in n.neighbors:
      result.add((n, c))

proc collides(a, b: Edge): bool =
  let
    aDelta = a.b.pos - a.a.pos
    aDir = aDelta.unit
    bDelta = b.b.pos - b.a.pos
    bDir = bDelta.unit
  const r = 0.2
  intersects(
    a.a.pos + r * aDir,
    a.b.pos - r * aDir,
    b.a.pos + r * bDir,
    b.b.pos - r * bDir)

proc hasCollisions(edges: seq[Edge], ): bool =
  for i in 0..<edges.len:
    let a = edges[i]
    for j in i+1..<edges.len:
      let b = edges[j]
      if collides(a, b):
        return true

proc tryFixCollisions(edges: seq[Edge], dt: float) =
  var forces = initTable[ref GraphNode, Vec]()
  for i in 0..<edges.len:
    let
      a = edges[i]
      aDelta = a.b.pos - a.a.pos
      aDir = aDelta.unit
    for j in i+1..<edges.len:
      let
        b = edges[j]
        bDelta = b.b.pos - b.a.pos
        bDir = bDelta.unit
      if collides(a, b):
        forces[a.a] = forces.getOrDefault(a.a) + bDir * (500 * dt)
        forces[a.b] = forces.getOrDefault(a.a) + bDir * (500 * dt)
        forces[b.a] = forces.getOrDefault(a.a) + aDir * (500 * dt)
        forces[b.b] = forces.getOrDefault(a.a) + aDir * (500 * dt)
  for n, f in forces:
    n.pos += f

proc applyForces(nodes: seq[ref GraphNode], dt: float): Vec =
  var forces = initTable[ref GraphNode, Vec]()
  for n in nodes:
    forces[n] = vec()

  for n in nodes:
    for c in nodes:
      if n == c:
        continue
      let
        delta = n.pos - c.pos
        length = delta.length
        dist = max(length / 100 * length, 10)
      forces[n] += delta.unit() * (1000 / dist)

    for c in n.neighbors:
      const idealLength = 100
      let
        delta = c.pos - n.pos
        dist = delta.length - idealLength
        toMove = delta.unit() * dist * dist / idealLength
      forces[n] += toMove
      forces[c] -= toMove

  var maxDrift = vec()
  for n in nodes:
    let toMove = forces[n] * dt
    maxDrift = max(toMove, maxDrift)
    n.pos += toMove
  return maxDrift

proc centerNodes(map: MapGen) =
  var centerPos = vec()
  for n in map.nodes:
    centerPos += n.pos
  centerPos = centerPos / map.nodes.len
  centerPos -= map.screenSize / 2
  for n in map.nodes:
    n.pos -= centerPos

method init(map: MapGen) =
  map.genMap(12)

method draw*(renderer: RendererPtr, map: MapGen) =
  let font = map.resources.loadFont fontName

  renderer.draw map.nodes, font, map.camera, map.zoomScale

method update*(map: MapGen, dt: float) =
  #TODO: split into subfunctions
  # maybe generate new map
  if map.input.isPressed(Input.spell1):
    nextId = 1
    map.genMap(random(27,31))

  # update camera position
  let mouse = map.input.clickHeldPos()
  map.lastMousePos.bindAs pos:
    mouse.bindAs mousePos:
      map.camera += pos - mousePos
  map.lastMousePos = mouse

  # update camera zoom
  let dWheel = map.input.mouseWheel
  if dWheel != 0:
    let center = map.camera - 0.5 * map.zoomScale * map.screenSize
    map.zoomLevel += dWheel
    map.zoomLevel = map.zoomLevel.clamp(0, zoomLevels)
    map.camera = center + 0.5 * map.zoomScale * map.screenSize

  # iterate map
  if map.stage == spacing:
    var maxDrift = vec()
    const
      driftThreshold = 3
      numSteps = 30
    for i in 0..numSteps:
      maxDrift = max(maxDrift, applyForces(map.nodes, 2 * dt))
    let edges = map.nodes.edges
    tryFixCollisions(edges, (1 + 0.025 * map.iterations.float / numSteps) * dt)
    if maxDrift.length < driftThreshold:
      map.stage = splitting
    map.iterations += numSteps
  elif map.stage == splitting:
    var
      didSplit = false
      toAdd: seq[ref GraphNode] = @[]
    for n in map.nodes:
      let length = n.neighbors.len + (if n.id == 1: 0 else: 1)
      if length > 4:
        echo "Splitting: ", n.id, " with neighbors=", length
        didSplit = true
        let x = newGraphNode()
        x.pos = n.pos + randomVec(30)
        shuffle(n.neighbors)
        while n.neighbors.len >= length div 2:
          x.neighbors.add n.neighbors[0]
          n.neighbors.del 0
        n.neighbors.add x
        toAdd.add x
    for n in toAdd:
      map.nodes.add n

    if didSplit:
      map.stage = spacing
      map.iterations = 0
    else:
      map.stage = legalizing
  elif map.stage == legalizing:
    #TODO: fix copy-paste from separating!!
    var maxDrift = vec()
    const
      driftThreshold = 3
      numSteps = 30
    for i in 0..numSteps:
      maxDrift = max(maxDrift, applyForces(map.nodes, 2 * dt))
    let edges = map.nodes.edges
    tryFixCollisions(edges, (1 + 0.025 * map.iterations.float / numSteps) * dt)
    if (not hasCollisions(edges)) and maxDrift.length < driftThreshold:
      map.stage = done
      echo "Done"
    map.iterations += numSteps

  map.centerNodes()

when isMainModule:
  let
    screenSize = vec(1200, 900)
    map = newMapGen(screenSize)
  main(map, screenSize)
