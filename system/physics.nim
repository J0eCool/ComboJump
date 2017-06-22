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

# New system:
# toMove = vel*dt
# while toMove.length > 0:
#   Raycast from each point on the entity through
#   Find the shortest-distance collision, move by that distance
#   Subtract moved distance from toMove, zero vel direction normal to collision

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
      toSet.setShortest RaycastHit(
        pos: pos,
        normal: normal,
        distance: distance,
      )

  if d.x > 0:
    result.calculateIntersection(
      target = rect.left,
      normal = vec(-1, 0),
    )
  elif d.x < 0:
    result.calculateIntersection(
      target = rect.right,
      normal = vec(1, 0),
    )
  if d.y > 0:
    result.calculateIntersection(
      target = rect.top,
      normal = vec(0, -1),
    )
  elif d.y < 0:
    result.calculateIntersection(
      target = rect.bottom,
      normal = vec(0, 1),
    )

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
            let
              ray = Ray(
                pos: rect.pos + toMove.sign * rect.size / 2,
                dir: toMove,
                dist: toMove.length,
              )
              col = ray.raycast(floorTransforms)
            if col.isNone:
              rect += toMove
              break
            col.bindAs hit:
              let delta = hit.normal * hit.distance * hit.normal.dot(toMove.unit)
              rect += delta
              toMove += hit.normal * toMove.abs
              if hit.normal.y < 0:
                movement.onGround = true
        # TODO: one way platforms
      transform.globalPos = rect.pos

