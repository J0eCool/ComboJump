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

defineSystem:
  priority = -1
  proc physics*(dt: float) =
    # Collect colliders once
    var
      floorTransforms: seq[Rect] = @[]
      platformTransforms: seq[Rect] = @[]
    entities.forComponents entity, [
      Collider, collider,
      Transform, transform,
    ]:
      proc add(rect: Rect) =
        if collider.layer == Layer.floor:
          floorTransforms.add(rect)
        elif collider.layer == Layer.oneWayPlatform:
          platformTransforms.add(rect)
      let roomViewer = entity.getComponent(RoomViewer)
      if roomViewer == nil:
        add(transform.globalRect)
        continue

      let
        data = roomViewer.data
        size = roomViewer.tileSize
      for x in 0..<data.len:
        for y in 0..<data[x].len:
          if data[x][y]:
            let pos = transform.globalPos + vec(x, y) * size
            add(rect(pos, size))

    # Do collisions
    entities.forComponents entity, [
      Movement, movement,
      Transform, transform,
    ]:
      if movement.usesGravity:
        movement.vel.y += gravity * dt

      var
        rect = transform.globalRect
        toMove = movement.vel * dt

      movement.onGround = false
      entity.withComponent Collider, collider:
        if collider.layer.canCollideWith Layer.floor:
          while toMove.length2 > 0.001:
            proc rayFrom(offset: Vec): Ray =
              Ray(
                pos: rect.pos + offset,
                dir: toMove,
                dist: toMove.length,
              )
            let
              xNum = 4
              yNum = 4
            var col = makeNone[RaycastHit]()
            if toMove.y != 0.0:
              for x in 0..<xNum:
                let
                  t = x / (xNum - 1)
                  offset = vec(t - 0.5, toMove.y.sign / 2) * rect.size
                col.setShortest rayFrom(offset).raycast(floorTransforms)
            if toMove.x != 0.0:
              for y in 0..<yNum:
                let
                  t = y / (yNum - 1)
                  offset = vec(toMove.x.sign / 2, t - 0.5) * rect.size
                col.setShortest rayFrom(offset).raycast(floorTransforms)
            if col.isNone:
              rect += toMove
              break
            col.bindAs hit:
              let delta = hit.normal * hit.distance * hit.normal.dot(toMove.unit)
              rect += delta
              toMove += hit.normal * toMove.abs
              if hit.normal.y < 0:
                movement.onGround = true
              if hit.normal.x == 0.0:
                movement.vel.y = 0.0
              else:
                movement.vel.x = 0.0
        # TODO: one way platforms
      transform.globalPos = rect.pos

