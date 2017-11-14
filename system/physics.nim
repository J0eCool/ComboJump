import
  component/[
    collider,
    movement,
    room_viewer,
    transform,
  ],
  mapgen/tile_room,
  entity,
  event,
  game_system,
  option,
  rect,
  util,
  vec

type
  ColliderData = tuple[entity: Entity, rect: Rect, collider: Collider]
  Ray* = object
    pos*: Vec
    dir*: Vec
    dist*: float
  RaycastHit* = object
    pos*: Vec
    normal*: Vec
    distance*: float

proc setShortest(toSet: var Option[RaycastHit], hit: RaycastHit) =
  if toSet.isNone:
    toSet = hit.makeJust
    return
  toSet.bindAs cur:
    if hit.distance < cur.distance:
      toSet = hit.makeJust

proc setShortest(toSet: var Option[RaycastHit], maybeHit: Option[RaycastHit]) =
  maybeHit.bindAs hit:
    toSet.setShortest(hit)

proc intersection*(ray: Ray, rect: Rect): Option[RaycastHit] =
  let d = ray.dir.unit * ray.dist
  proc calculateIntersection(
      toSet: var Option[RaycastHit],
      toHitEdge: var bool,
      target = 0.0,
      normal = vec(),
     ) =
    let
      isX = normal.x != 0
      (main, sub) = if isX: (getX, getY) else: (getY, getX)
      m = d.sub / d.main
      dx = -normal.main * (target - ray.pos.main)
      y = m * dx + ray.pos.sub
    if dx >= 0.0 and dx <= ray.dist and
        ((isX and y >= rect.top and y <= rect.bottom) or
         (not isX and y >= rect.left and y <= rect.right)):
      let
        pos = if isX: vec(target, y) else: vec(y, target)
        distance = ray.pos.distance(pos)
      toHitEdge = ((isX and (y == rect.top or y == rect.bottom)) or
                 (not isX and (y == rect.left or y == rect.right)))

      var hit = RaycastHit(
        pos: pos,
        normal: normal,
        distance: distance,
      )
      if isX or toSet.isNone:
        toSet = hit.makeJust
      else:
        toSet.bindAs pre:
          hit.normal = unit(hit.normal + pre.normal)
          toSet = hit.makeJust

  var
    hitEdgeX = false
    hitEdgeY = false
  if d.x > 0:
    result.calculateIntersection(
      hitEdgeX,
      target = rect.left,
      normal = vec(-1, 0),
    )
  elif d.x < 0:
    result.calculateIntersection(
      hitEdgeX,
      target = rect.right,
      normal = vec(1, 0),
    )
  if d.y > 0:
    result.calculateIntersection(
      hitEdgeY,
      target = rect.top,
      normal = vec(0, -1),
    )
  elif d.y < 0:
    result.calculateIntersection(
      hitEdgeY,
      target = rect.bottom,
      normal = vec(0, 1),
    )
  if hitEdgeX xor hitEdgeY:
    result = makeNone[RaycastHit]()

proc raycast*(ray: Ray, colliders: seq[Rect]): Option[RaycastHit] =
  for collider in colliders:
    let col = ray.intersection(collider)
    col.bindAs hit:
      result.setShortest hit

proc collectTerrain(entities: Entities): seq[Rect] =
  result = @[]
  entities.forComponents entity, [
    Collider, collider,
    Transform, transform,
  ]:
    let roomViewer = entity.getComponent(RoomViewer)
    if roomViewer == nil:
      if collider.layer == Layer.floor:
        result.add transform.globalRect
      continue

    let
      data = roomViewer.data
      size = roomViewer.tileSize
    for x in 0..<data.len:
      for y in 0..<data[x].len:
        if data[x][y]:
          let pos = transform.globalPos + vec(x, y) * size
          result.add rect(pos, size)

defineSystem:
  priority = -1
  proc physics*(dt: float) =
    # Collect colliders once
    let floorRects: seq[Rect] = collectTerrain(entities)
    proc doesCollide(cur: Rect): bool =
      for r in floorRects:
        if r.intersects(cur):
          return true
      return false

    proc binarySearch(rect: var Rect, pre: Vec, startedCollided: bool) =
      var
        lo = pre
        hi = rect.pos
      for _ in 0..<10:
        rect.pos = (hi + lo) / 2
        if rect.doesCollide xor startedCollided:
          hi = rect.pos
        else:
          lo = rect.pos
      if rect.doesCollide:
        if startedCollided:
          rect.pos = hi
        else:
          rect.pos = lo

    # Do collisions
    entities.forComponents entity, [
      Movement, movement,
      Transform, transform,
    ]:
      if movement.usesGravity:
        movement.vel.y += gravity * dt

      movement.onGround = false

      entity.withComponent Collider, collider:
        var
          rect = transform.globalRect
          toMove = movement.vel * dt
        let size = rect.size

        if not collider.layer.canCollideWith Layer.floor:
          transform.pos += toMove
          continue

        if rect.doesCollide:
          # If starting in ground, need to fix
          var fixes = [
            vec(1, 0),
            vec(-1, 0),
            vec(0, 1),
            vec(0, -1),
          ]
          let pre = rect.pos
          var colliding = true
          while colliding:
            for i in 0..<4:
              rect.pos = pre + fixes[i]
              if not rect.doesCollide:
                colliding = false
                break
              fixes[i] = fixes[i] * 2
          rect.binarySearch(pre, startedCollided=true)

        var atMost = 2
        while toMove.length2 > 0.001:
          atMost -= 1
          let pre = rect.pos
          rect += toMove
          let collided = rect.doesCollide
          if collided:
            rect.binarySearch(pre, startedCollided=false)
          toMove -= rect.pos - pre
          if collided:
            let hitX = rect(rect.pos + vec(1 * sign(toMove.x), 0), size).doesCollide
            if hitX:
              toMove.x = 0.0
              movement.vel.x = 0.0
            else:
              toMove.y = 0.0
              movement.vel.y = 0.0
              movement.onGround = true

        transform.globalPos = rect.pos

