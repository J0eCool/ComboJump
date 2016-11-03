import
  algorithm,
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

var nextId = 1
type
  Direction = enum
    left,
    up,
    right,
    down

  GraphNode = ref object
    id: int
    pos: Vec
    neighbors: seq[GraphNode]
    usedDirs: set[Direction]
    dirToParent: Vec

proc newGraphNode(): GraphNode =
  new result
  result.id = nextId
  result.neighbors = @[]
  nextId += 1

proc hash(node: GraphNode): Hash =
  node.id.Hash

proc firstItem[T](s: HashSet[T]): T = 
  assert(s.len > 0) 
  for x in s.items: 
    return x

proc toSeq[T](s: HashSet[T]): seq[T] =
  result = @[]
  for x in s.items:
    result.add x

proc traverse(node: GraphNode): seq[GraphNode] =
  result = @[] 
  var 
    openSet = initSet[GraphNode]() 
    closedSet = initSet[GraphNode]() 
 
  openSet.incl node 
  closedSet.incl node 
 
  while openSet.len > 0: 
    let n = openSet.firstItem 
    openSet.excl n 
 
    result.add n 
    for c in n.neighbors: 
      if (not closedSet.contains(c)): 
        openSet.incl c 
        closedSet.incl c 

proc numChildren(node: GraphNode): int =
  node.traverse.len

proc moveWithChildren(node: GraphNode, toMove: Vec) =
  for n in node.traverse:
    n.pos += toMove

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

var textCache = initTable[string, RenderedText]()
proc drawCachedText(renderer: RendererPtr, text: string, pos: Vec, font: FontPtr, color: Color) =
  if not textCache.hasKey(text):
    textCache[text] = renderer.renderText(text, font, color)
  renderer.draw(textCache[text], pos)

proc draw(renderer: RendererPtr, nodes: seq[GraphNode], font: FontPtr, camera: Vec, zoom: float) =
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
    renderer.drawCachedText(text, pos, font, color(64, 64, 64, 255))

type
  Stage = enum
    spacing,
    splitting,
    legalizing,
    uncrossing,
    preDone,
    done

  MapGen* = ref object of Program
    nodes: seq[GraphNode]
    resources: ResourceManager
    camera: Vec
    lastMousePos: Option[Vec]
    zoomLevel: int
    screenSize: Vec
    stage: Stage
    iterations: int
    paused: bool
    shouldAutoPause: bool
    legalizingNode: int
    legalizingChild: int
    loggingStages: set[Stage]

proc initDirToVec(): array[Direction, Vec] =
  result[left] = vec(-1, 0)
  result[right] = vec(1, 0)
  result[up] = vec(0, -1)
  result[down] = vec(0, 1)
proc initDirToOpposite(): array[Direction, Direction] =
  result[left] = right
  result[right] = left
  result[up] = down
  result[down] = up

const
  zoomLevels = 15
  zoomPower = 1.3
  midZoomLevel = zoomLevels div 2
  dirToVec = initDirToVec()
  dirToOpposite = initDirToOpposite()
  allDirs = {right, down, up, left}

proc newMapGen(screenSize: Vec): MapGen =
  new result
  result.screenSize = screenSize
  result.resources = newResourceManager()
  result.zoomLevel = midZoomLevel
  result.loggingStages = {}
  result.initProgram()

template log(map: MapGen, stage: Stage, message: varargs[untyped]) =
  if stage in map.loggingStages:
    addVarargs(echo(), message)

proc zoomScale(map: MapGen): float =
  let lvl = map.zoomLevel - midZoomLevel
  pow(zoomPower, lvl.float)

proc genMap(map: MapGen, numNodes: int) =
  var nodes: seq[GraphNode] = @[]

  for i in 0..<numNodes:
    let n = newGraphNode()
    n.pos = vec(random(100, 1100), random(100, 800))
    if i > 0:
      nodes[random(0, i-1)].neighbors.add n
    nodes.add n

  map.nodes = nodes
  map.stage = spacing
  map.iterations = 0
  map.legalizingNode = 0
  map.legalizingChild = 0
  map.camera = vec()
  echo "New map with ", numNodes, " nodes"

type Edge = tuple[a, b: GraphNode]
proc edges(nodes: seq[GraphNode]): seq[Edge] =
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
  const r = -50
  return (
    a.a != b.a and
    a.a != b.b and
    a.b != b.a and
    a.b != b.b and
    intersects(
      a.a.pos + r * aDir,
      a.b.pos - r * aDir,
      b.a.pos + r * bDir,
      b.b.pos - r * bDir)
    )

template walkCollisions(edges: seq[Edge], a, b, body: untyped): untyped =
  for i in 0..<edges.len:
    let a = edges[i]
    for j in i+1..<edges.len:
      let b = edges[j]
      if collides(a, b):
        body

proc hasCollisions(edges: seq[Edge]): bool =
  edges.walkCollisions a, b:
    return true

proc nodesWithCollisions(edges: seq[Edge]): HashSet[GraphNode] =
  result = initSet[GraphNode]()
  edges.walkCollisions a, b:
    result.incl a.a
    result.incl a.b
    result.incl b.a
    result.incl b.b

proc tryFixCollisions(edges: seq[Edge], dt: float) =
  var forces = initTable[GraphNode, Vec]()
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
        let dirs = [bDir, aDir]
        var i = 0
        for n in [a.a, b.a, a.b, b.b]:
          forces[n] = forces.getOrDefault(n) + dirs[i mod 2] * (500 * dt)
          i += 1
  for n, f in forces:
    n.pos += f

proc applyForces(nodes: seq[GraphNode], dt: float): Vec =
  var forces = initTable[GraphNode, Vec]()
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

proc sortedByChildCount(nodes: seq[GraphNode]): seq[GraphNode] =
  result = nodes
  result.sort(
    proc (a, b: GraphNode): int =
      system.cmp[int](a.numChildren, b.numChildren)
  )

proc updateSpacing(map: MapGen, dt: float) =
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
    map.paused = map.shouldAutoPause
  map.iterations += numSteps

proc updateSplitting(map: MapGen) =
  var
    didSplit = false
    toAdd: seq[GraphNode] = @[]
  for n in map.nodes:
    let length = n.neighbors.len + (if n.id == 1: 0 else: 1)
    if length > 4:
      map.log splitting, "Splitting: ", n.id, " with neighbors=", length
      didSplit = true
      let x = newGraphNode()
      x.pos = n.pos + randomVec(150, 300)
      shuffle(n.neighbors)
      while n.neighbors.len > length div 2:
        x.neighbors.add n.neighbors[0]
        n.neighbors.del 0
      n.neighbors.add x
      toAdd.add x
  for n in toAdd:
    map.nodes.add n

  if not didSplit:
    map.log splitting, "Done splitting"
    map.stage = legalizing
    map.paused = map.shouldAutoPause

proc updateLegalizing(map: MapGen) =
  if map.legalizingNode >= map.nodes.len:
    map.stage = uncrossing
  else:
    let node = map.nodes[map.legalizingNode]
    if map.legalizingChild >= node.neighbors.len:
      map.legalizingNode += 1
      map.legalizingChild = 0
    else:
      let sortedNeighbors = node.neighbors.sortedByChildCount
      let
        child = sortedNeighbors[map.legalizingChild]
        delta = child.pos - node.pos
        dirs = allDirs - node.usedDirs
      var
        bestDir: Option[Direction]
        bestDiff = 0.0
      for d in dirs:
        case bestDir.kind
        of option.none:
          bestDir = makeJust d
          bestDiff = delta.dot dirToVec[d]
        of option.just:
          let diff = delta.dot dirToVec[d]
          if diff > bestDiff:
            bestDir = makeJust d
            bestDiff = diff
      let
        d = bestDir.value
        op = dirToOpposite[d]
        toMove = node.pos - child.pos + dirToVec[d] * delta.length
      child.moveWithChildren toMove
      node.usedDirs = node.usedDirs + {d}
      child.usedDirs = child.usedDirs + {op}
      child.dirToParent = dirToVec[op]

      map.log legalizing, "Moving <", child.id, "> to <", d, "> of <", node.id, ">"

      map.legalizingChild += 1

proc updateUncrossing(map: MapGen, dt: float) =
  let crosses = map.nodes.edges.nodesWithCollisions
  if crosses.len == 0:
    map.stage = preDone
    return
  let
    nodes = crosses.toSeq.sortedByChildCount
    node = nodes[nodes.len - 1]
    toMove = node.dirToParent * dt * 2500
  node.moveWithChildren toMove


method init(map: MapGen) =
  map.genMap(12)
  map.shouldAutoPause = false

method draw*(renderer: RendererPtr, map: MapGen) =
  let
    font = map.resources.loadFont fontName
    stageText = "Stage: " & $map.stage

  renderer.draw map.nodes, font, map.camera, map.zoomScale
  renderer.drawCachedText stageText, vec(600, 830), font, color(64, 64, 64, 255)

method update*(map: MapGen, dt: float) =
  #TODO: split into subfunctions
  # maybe generate new map
  if map.input.isPressed(Input.spell1):
    nextId = 1
    map.genMap(random(7,55))
  if map.input.isPressed(Input.jump):
    map.paused = not map.paused

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

  if map.paused:
    return

  # iterate map
  case map.stage
  of spacing:
    map.updateSpacing(dt)
  of splitting:
    map.updateSplitting()
  of legalizing:
    map.updateLegalizing()
  of uncrossing:
    map.updateUncrossing(dt)
  of preDone:
    echo "Done"
    map.stage = done
  of done:
    discard

  map.centerNodes()

when isMainModule:
  let
    screenSize = vec(1200, 900)
    map = newMapGen(screenSize)
  main(map, screenSize)
